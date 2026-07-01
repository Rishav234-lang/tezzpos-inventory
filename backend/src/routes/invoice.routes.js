const { handleError, NotFoundError } = require('../utils/errors');
const { generateInvoicePDF, generatePurchaseInvoicePDF, generateSaleReturnPDF } = require('../utils/invoice-generator');

async function invoiceRoutes(fastify) {
  fastify.addHook('preHandler', fastify.authenticateOwner);
  fastify.addHook('preHandler', fastify.checkSubscription);

  // Download PDF invoice for a sale
  fastify.get('/sales/:id/pdf', async (request, reply) => {
    try {
      const companyId = request.user.companyId;

      const sale = await fastify.prisma.sale.findFirst({
        where: { id: request.params.id, companyId },
        include: {
          customer: { select: { id: true, name: true, mobile: true, address: true, gstNumber: true } },
          items: {
            include: {
              product: { select: { id: true, name: true, sku: true, hsnCode: true } },
              batch:   { select: { batchNumber: true } },
            },
          },
        },
      });

      if (!sale) throw new NotFoundError('Sale');

      const company = await fastify.prisma.company.findUnique({
        where: { id: companyId },
        select: { name: true, email: true, phone: true, address: true, gstNumber: true },
      });

      const pdfBuffer = await generateInvoicePDF(sale, company);

      reply
        .header('Content-Type', 'application/pdf')
        .header('Content-Disposition', `attachment; filename="INV-${sale.invoiceNumber}.pdf"`)
        .header('Content-Length', pdfBuffer.length)
        .send(pdfBuffer);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Inline preview (open in browser)
  fastify.get('/sales/:id/preview', async (request, reply) => {
    try {
      const companyId = request.user.companyId;

      const sale = await fastify.prisma.sale.findFirst({
        where: { id: request.params.id, companyId },
        include: {
          customer: { select: { id: true, name: true, mobile: true, address: true, gstNumber: true } },
          items: {
            include: {
              product: { select: { id: true, name: true, sku: true, hsnCode: true } },
              batch:   { select: { batchNumber: true } },
            },
          },
        },
      });

      if (!sale) throw new NotFoundError('Sale');

      const company = await fastify.prisma.company.findUnique({
        where: { id: companyId },
        select: { name: true, email: true, phone: true, address: true, gstNumber: true },
      });

      const pdfBuffer = await generateInvoicePDF(sale, company);

      reply
        .header('Content-Type', 'application/pdf')
        .header('Content-Disposition', `inline; filename="INV-${sale.invoiceNumber}.pdf"`)
        .send(pdfBuffer);
    } catch (error) {
      handleError(reply, error);
    }
  });
  // Download PDF invoice for a purchase
  fastify.get('/purchases/:id/pdf', async (request, reply) => {
    try {
      const companyId = request.user.companyId;

      const purchase = await fastify.prisma.purchase.findFirst({
        where: { id: request.params.id, companyId },
        include: {
          vendor: { select: { id: true, name: true, mobile: true, address: true, gstNumber: true } },
          items: {
            include: {
              product: { select: { id: true, name: true, sku: true } },
            },
          },
        },
      });

      if (!purchase) throw new NotFoundError('Purchase');

      const company = await fastify.prisma.company.findUnique({
        where: { id: companyId },
        select: { name: true, email: true, phone: true, address: true, gstNumber: true },
      });

      const pdfBuffer = await generatePurchaseInvoicePDF(purchase, company);

      reply
        .header('Content-Type', 'application/pdf')
        .header('Content-Disposition', `attachment; filename="PUR-${purchase.invoiceNumber}.pdf"`)
        .header('Content-Length', pdfBuffer.length)
        .send(pdfBuffer);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Inline preview for a purchase invoice
  fastify.get('/purchases/:id/preview', async (request, reply) => {
    try {
      const companyId = request.user.companyId;

      const purchase = await fastify.prisma.purchase.findFirst({
        where: { id: request.params.id, companyId },
        include: {
          vendor: { select: { id: true, name: true, mobile: true, address: true, gstNumber: true } },
          items: {
            include: {
              product: { select: { id: true, name: true, sku: true } },
            },
          },
        },
      });

      if (!purchase) throw new NotFoundError('Purchase');

      const company = await fastify.prisma.company.findUnique({
        where: { id: companyId },
        select: { name: true, email: true, phone: true, address: true, gstNumber: true },
      });

      const pdfBuffer = await generatePurchaseInvoicePDF(purchase, company);

      reply
        .header('Content-Type', 'application/pdf')
        .header('Content-Disposition', `inline; filename="PUR-${purchase.invoiceNumber}.pdf"`)
        .send(pdfBuffer);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // ── Sale Return PDF ──────────────────────────────────────────────────────
  fastify.get('/sale-returns/:id/pdf', async (request, reply) => {
    try {
      const companyId = request.user.companyId;
      const saleReturn = await fastify.prisma.saleReturn.findFirst({
        where: { id: request.params.id, companyId },
        include: {
          customer: { select: { id: true, name: true, mobile: true } },
          sale: { select: { invoiceNumber: true } },
          items: {
            include: { product: { select: { name: true, sku: true } } },
          },
        },
      });
      if (!saleReturn) {
        return reply.code(404).send({ error: 'Sale return not found' });
      }
      const company = await fastify.prisma.company.findUnique({
        where: { id: companyId },
        select: { name: true, email: true, address: true, gstNumber: true },
      });
      const pdfBuffer = await generateSaleReturnPDF(saleReturn, company);
      reply
        .header('Content-Type', 'application/pdf')
        .header('Content-Disposition', `attachment; filename="return-${saleReturn.returnNumber}.pdf"`)
        .send(pdfBuffer);
    } catch (error) {
      handleError(reply, error);
    }
  });
}

module.exports = invoiceRoutes;
