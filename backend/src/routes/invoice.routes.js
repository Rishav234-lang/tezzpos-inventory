const { handleError, NotFoundError } = require('../utils/errors');
const { generateInvoicePDF } = require('../utils/invoice-generator');

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
}

module.exports = invoiceRoutes;
