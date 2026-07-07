const { saleSchema } = require('../utils/validators');
const { handleError, NotFoundError, ValidationError } = require('../utils/errors');
const { getPaginationParams, createPaginatedResponse } = require('../utils/pagination');
const { convertPrismaToJson } = require('../utils/convertPrisma');

async function saleRoutes(fastify) {
  fastify.addHook('preHandler', fastify.authenticateOwner);
  fastify.addHook('preHandler', fastify.checkSubscription);

  // Create Sale (FIFO stock deduction)
  fastify.post('/', async (request, reply) => {
    try {
      const data = saleSchema.parse(request.body);
      const companyId = request.user.companyId;

      const result = await fastify.prisma.$transaction(async (tx) => {
        // Atomic invoice number via upsert on CompanyCounter (race-condition safe)
        const counter = await tx.companyCounter.upsert({
          where:  { companyId },
          create: { companyId, saleCounter: 1 },
          update: { saleCounter: { increment: 1 } },
        });
        const invoiceNumber = `INV-${new Date().getFullYear()}-${String(counter.saleCounter).padStart(6, '0')}`;

        const isInterState = data.isInterState || false;

        // Process items with FIFO + GST calculation
        const processedItems = [];
        let subtotal = 0;
        let totalCGST = 0, totalSGST = 0, totalIGST = 0;

        for (const item of data.items) {
          // Fetch product to get gstRate
          const product = await tx.product.findUnique({
            where: { id: item.productId },
            select: { name: true, gstRate: true },
          });

          // Get available batches in FIFO order (oldest first)
          const batches = await tx.batch.findMany({
            where: { companyId, productId: item.productId, status: 'ACTIVE', availableQuantity: { gt: 0 } },
            orderBy: { purchaseDate: 'asc' },
          });

          const totalAvailable = batches.reduce((sum, b) => sum + b.availableQuantity, 0);
          if (totalAvailable < item.quantity) {
            throw new ValidationError(
              `Insufficient stock for ${product?.name || item.productId}. Available: ${totalAvailable}, Requested: ${item.quantity}`
            );
          }

          // Deduct stock using FIFO
          let remainingQty = item.quantity;
          let assignedBatchId = null;

          for (const batch of batches) {
            if (remainingQty <= 0) break;
            const deductQty = Math.min(remainingQty, batch.availableQuantity);
            const newAvailable = batch.availableQuantity - deductQty;
            await tx.batch.update({
              where: { id: batch.id },
              data: { availableQuantity: newAvailable, status: newAvailable === 0 ? 'DEPLETED' : 'ACTIVE' },
            });
            if (!assignedBatchId) assignedBatchId = batch.id;
            remainingQty -= deductQty;
          }

          // GST calculation
          const gstRate = Number(product?.gstRate || item.gstRate || 0);
          const taxableAmt = item.quantity * item.sellingPrice - Number(item.discount || 0);
          let cgstRate = 0, sgstRate = 0, igstRate = 0;
          let cgstAmt  = 0, sgstAmt  = 0, igstAmt  = 0;

          if (gstRate > 0) {
            if (isInterState) {
              igstRate = gstRate;
              igstAmt  = parseFloat(((taxableAmt * igstRate) / 100).toFixed(2));
            } else {
              cgstRate = gstRate / 2;
              sgstRate = gstRate / 2;
              cgstAmt  = parseFloat(((taxableAmt * cgstRate) / 100).toFixed(2));
              sgstAmt  = parseFloat(((taxableAmt * sgstRate) / 100).toFixed(2));
            }
          }

          const itemTaxAmt = cgstAmt + sgstAmt + igstAmt;
          const itemTotal  = taxableAmt + itemTaxAmt;

          totalCGST += cgstAmt;
          totalSGST += sgstAmt;
          totalIGST += igstAmt;
          subtotal  += taxableAmt;

          processedItems.push({
            productId:    item.productId,
            batchId:      assignedBatchId,
            quantity:     item.quantity,
            sellingPrice: item.sellingPrice,
            discount:     item.discount || 0,
            cgstRate,  sgstRate,  igstRate,
            cgstAmount: cgstAmt, sgstAmount: sgstAmt, igstAmount: igstAmt,
            taxAmount:  itemTaxAmt,
            totalAmount: itemTotal,
          });
        }

        const saleLevelDiscount = Number(data.discount || 0);
        const totalTax    = totalCGST + totalSGST + totalIGST;
        const totalAmount = subtotal - saleLevelDiscount + totalTax;
        const balanceAmount = totalAmount - data.paidAmount;
        let status = 'UNPAID';
        if (data.paidAmount >= totalAmount) status = 'PAID';
        else if (data.paidAmount > 0)        status = 'PARTIAL';

        const sale = await tx.sale.create({
          data: {
            companyId,
            customerId:    data.customerId,
            invoiceNumber,
            invoiceDate:   data.invoiceDate ? new Date(data.invoiceDate) : new Date(),
            subtotal,
            discount:      saleLevelDiscount,
            taxAmount:     totalTax,
            cgstAmount:    totalCGST,
            sgstAmount:    totalSGST,
            igstAmount:    totalIGST,
            isInterState,
            totalAmount,
            paidAmount:    data.paidAmount,
            balanceAmount,
            paymentMethod: data.paymentMethod,
            status,
            notes:         data.notes,
            items: { create: processedItems },
          },
          include: {
            customer: { select: { id: true, name: true, mobile: true, gstNumber: true } },
            items: { include: { product: { select: { id: true, name: true, sku: true, hsnCode: true } } } },
          },
        });

        return sale;
      }, {
        timeout: 15000,
      });

      return reply.status(201).send(convertPrismaToJson(result));
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Get All Sales
  fastify.get('/', async (request, reply) => {
    try {
      const { page, limit, skip } = getPaginationParams(request.query);
      const { customerId, status, startDate, endDate } = request.query;
      const companyId = request.user.companyId;

      const where = { companyId };
      if (customerId) where.customerId = customerId;
      if (status) where.status = status;
      if (startDate || endDate) {
        where.invoiceDate = {};
        if (startDate) where.invoiceDate.gte = new Date(startDate);
        if (endDate) where.invoiceDate.lte = new Date(endDate);
      }

      const [sales, total] = await Promise.all([
        fastify.prisma.sale.findMany({
          where,
          include: {
            customer: { select: { id: true, name: true } },
            _count: { select: { items: true } },
          },
          skip,
          take: limit,
          orderBy: { invoiceDate: 'desc' },
        }),
        fastify.prisma.sale.count({ where }),
      ]);

      return createPaginatedResponse(convertPrismaToJson(sales), total, page, limit);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Update Sale Payment/Status
  fastify.patch('/:id', async (request, reply) => {
    try {
      const { paidAmount, status, notes } = request.body;
      const companyId = request.user.companyId;

      const existing = await fastify.prisma.sale.findFirst({
        where: { id: request.params.id, companyId },
      });
      if (!existing) throw new NotFoundError('Sale');

      const newPaid = paidAmount !== undefined ? Number(paidAmount) : existing.paidAmount;
      const newStatus = status || (newPaid >= existing.totalAmount ? 'PAID' : newPaid > 0 ? 'PARTIAL' : 'UNPAID');
      const newBalance = existing.totalAmount - newPaid;

      const updated = await fastify.prisma.sale.update({
        where: { id: request.params.id },
        data: {
          paidAmount: newPaid,
          status: newStatus,
          balanceAmount: newBalance,
          notes: notes !== undefined ? notes : existing.notes,
        },
        include: {
          customer: true,
          items: { include: { product: { select: { id: true, name: true, sku: true, barcode: true } }, batch: { select: { id: true, batchNumber: true } } } },
        },
      });

      return convertPrismaToJson(updated);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Get Sale by ID
  fastify.get('/:id', async (request, reply) => {
    try {
      const rawSale = await fastify.prisma.sale.findFirst({
        where: { id: request.params.id, companyId: request.user.companyId },
        include: {
          customer: true,
          items: {
            include: {
              product: { select: { id: true, name: true, sku: true, barcode: true } },
              batch: { select: { id: true, batchNumber: true } },
            },
          },
        },
      });
      if (!rawSale) throw new NotFoundError('Sale');
      return convertPrismaToJson(rawSale);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Search Sales by Invoice Number
  fastify.get('/search/:invoiceNumber', async (request, reply) => {
    try {
      const sales = await fastify.prisma.sale.findMany({
        where: {
          companyId: request.user.companyId,
          invoiceNumber: { contains: request.params.invoiceNumber, mode: 'insensitive' },
        },
        include: { customer: { select: { id: true, name: true } } },
        take: 10,
      });
      return convertPrismaToJson(sales);
    } catch (error) {
      handleError(reply, error);
    }
  });
}

module.exports = saleRoutes;
