const PDFDocument = require('pdfkit');

/**
 * Generate a GST-compliant tax invoice PDF.
 * @param {object} sale  - Sale object with items, customer, and all GST fields
 * @param {object} company - Company object with name, address, email, gstNumber
 * @returns {Promise<Buffer>}
 */
function generateInvoicePDF(sale, company) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ margin: 40, size: 'A4' });
    const buffers = [];
    doc.on('data', (chunk) => buffers.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(buffers)));
    doc.on('error', reject);

    const PAGE_W = doc.page.width - 80; // usable width
    const L = 40; // left margin
    const R = L + PAGE_W; // right edge

    // ── Header ──────────────────────────────────────────────────────────────
    doc.fontSize(18).font('Helvetica-Bold').text('TAX INVOICE', L, 40, { align: 'center', width: PAGE_W });
    doc.moveDown(0.3);

    // Divider
    doc.moveTo(L, doc.y).lineTo(R, doc.y).lineWidth(1.5).stroke();
    doc.moveDown(0.4);

    // ── Company + Invoice Meta (two-column) ──────────────────────────────────
    const leftX = L;
    const rightX = L + PAGE_W / 2;
    const topY = doc.y;

    doc.fontSize(12).font('Helvetica-Bold').text(company.name, leftX, topY);
    doc.fontSize(8).font('Helvetica');
    if (company.address) doc.text(company.address, leftX);
    if (company.phone) doc.text(`Phone: ${company.phone}`, leftX);
    doc.text(`Email: ${company.email}`, leftX);
    if (company.gstNumber) doc.text(`GSTIN: ${company.gstNumber}`, leftX);

    // Invoice meta (right column)
    doc.fontSize(8).font('Helvetica-Bold').text('Invoice No:', rightX, topY, { continued: true });
    doc.font('Helvetica').text(` ${sale.invoiceNumber}`);
    doc.font('Helvetica-Bold').text('Date:', rightX, doc.y, { continued: true });
    doc.font('Helvetica').text(` ${new Date(sale.invoiceDate).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })}`);
    doc.font('Helvetica-Bold').text('Payment:', rightX, doc.y, { continued: true });
    doc.font('Helvetica').text(` ${sale.paymentMethod || 'CASH'}`);
    doc.font('Helvetica-Bold').text('Status:', rightX, doc.y, { continued: true });
    doc.font('Helvetica').text(` ${sale.status}`);

    doc.moveDown(0.8);
    doc.moveTo(L, doc.y).lineTo(R, doc.y).lineWidth(0.5).stroke();
    doc.moveDown(0.4);

    // ── Bill To ──────────────────────────────────────────────────────────────
    if (sale.customer) {
      doc.fontSize(9).font('Helvetica-Bold').text('BILL TO', L);
      doc.fontSize(8).font('Helvetica')
        .text(sale.customer.name)
        .text(sale.customer.mobile || '')
        .text(sale.customer.address || '')
        .text(sale.customer.gstNumber ? `GSTIN: ${sale.customer.gstNumber}` : '');
      doc.moveDown(0.5);
    }

    doc.moveTo(L, doc.y).lineTo(R, doc.y).lineWidth(0.5).stroke();

    // ── Items Table Header ────────────────────────────────────────────────────
    const COL = { no: L, item: L + 22, qty: L + 255, rate: L + 295, disc: L + 345, gst: L + 385, amt: L + 430 };
    const tableHeaderY = doc.y + 6;

    doc.fontSize(7.5).font('Helvetica-Bold');
    doc.text('#',         COL.no,   tableHeaderY, { width: 20 });
    doc.text('Item / HSN', COL.item, tableHeaderY, { width: 230 });
    doc.text('Qty',       COL.qty,  tableHeaderY, { width: 38, align: 'right' });
    doc.text('Rate',      COL.rate, tableHeaderY, { width: 48, align: 'right' });
    doc.text('Disc',      COL.disc, tableHeaderY, { width: 43, align: 'right' });
    doc.text('GST',       COL.gst,  tableHeaderY, { width: 43, align: 'right' });
    doc.text('Amount',    COL.amt,  tableHeaderY, { width: PAGE_W - (COL.amt - L), align: 'right' });

    let y = tableHeaderY + 13;
    doc.moveTo(L, y).lineTo(R, y).lineWidth(0.5).stroke();
    y += 5;

    // ── Item Rows ─────────────────────────────────────────────────────────────
    let totalCGST = 0, totalSGST = 0, totalIGST = 0;
    const gstGroups = {};

    sale.items.forEach((item, i) => {
      const cgst   = Number(item.cgstAmount || 0);
      const sgst   = Number(item.sgstAmount || 0);
      const igst   = Number(item.igstAmount || 0);
      totalCGST += cgst;
      totalSGST += sgst;
      totalIGST += igst;

      const gstAmt  = cgst + sgst + igst;
      const gstRate = Number(item.cgstRate || 0) + Number(item.sgstRate || 0) + Number(item.igstRate || 0);
      const hsnLine = item.product?.hsnCode ? `HSN: ${item.product.hsnCode}` : '';

      // Track for GST summary table
      const gKey = `${gstRate}`;
      if (!gstGroups[gKey]) {
        gstGroups[gKey] = { rate: gstRate, cgstRate: Number(item.cgstRate || 0), sgstRate: Number(item.sgstRate || 0), igstRate: Number(item.igstRate || 0), taxable: 0, cgst: 0, sgst: 0, igst: 0 };
      }
      const taxableAmt = Number(item.sellingPrice) * item.quantity - Number(item.discount || 0);
      gstGroups[gKey].taxable += taxableAmt;
      gstGroups[gKey].cgst   += cgst;
      gstGroups[gKey].sgst   += sgst;
      gstGroups[gKey].igst   += igst;

      doc.fontSize(7.5).font('Helvetica');
      doc.text(`${i + 1}`,           COL.no,   y, { width: 20 });
      doc.text(item.product?.name || '', COL.item, y, { width: 230 });
      if (hsnLine) {
        doc.fontSize(6.5).fillColor('#666666').text(hsnLine, COL.item, y + 10, { width: 230 });
        doc.fontSize(7.5).fillColor('#000000');
      }
      doc.text(`${item.quantity}`,                           COL.qty,  y, { width: 38,  align: 'right' });
      doc.text(`₹${Number(item.sellingPrice).toFixed(2)}`,   COL.rate, y, { width: 48,  align: 'right' });
      doc.text(`₹${Number(item.discount || 0).toFixed(2)}`,  COL.disc, y, { width: 43,  align: 'right' });
      doc.text(`₹${gstAmt.toFixed(2)}`,                      COL.gst,  y, { width: 43,  align: 'right' });
      doc.text(`₹${Number(item.totalAmount).toFixed(2)}`,    COL.amt,  y, { width: PAGE_W - (COL.amt - L), align: 'right' });

      y += hsnLine ? 22 : 16;

      // Page break guard
      if (y > doc.page.height - 200) {
        doc.addPage();
        y = 40;
      }
    });

    doc.moveTo(L, y).lineTo(R, y).lineWidth(0.5).stroke();
    y += 8;

    // ── Totals (right-aligned block) ──────────────────────────────────────────
    const TLABEL = R - 175;
    const TVAL   = R - 80;
    const TVALW  = 80;

    const addTotalRow = (label, value, bold = false) => {
      doc.fontSize(8).font(bold ? 'Helvetica-Bold' : 'Helvetica');
      doc.text(label, TLABEL, y, { width: 90, align: 'right' });
      doc.text(value,  TVAL,   y, { width: TVALW, align: 'right' });
      y += 14;
    };

    addTotalRow('Subtotal:', `₹${Number(sale.subtotal).toFixed(2)}`);
    if (Number(sale.discount) > 0) addTotalRow('Discount:', `- ₹${Number(sale.discount).toFixed(2)}`);
    if (totalCGST > 0) {
      addTotalRow('CGST:', `₹${totalCGST.toFixed(2)}`);
      addTotalRow('SGST:', `₹${totalSGST.toFixed(2)}`);
    }
    if (totalIGST > 0) addTotalRow('IGST:', `₹${totalIGST.toFixed(2)}`);

    doc.moveTo(TLABEL, y).lineTo(R, y).lineWidth(0.5).stroke();
    y += 4;
    addTotalRow('TOTAL:', `₹${Number(sale.totalAmount).toFixed(2)}`, true);
    doc.moveTo(TLABEL, y - 2).lineTo(R, y - 2).lineWidth(1).stroke();
    y += 4;
    addTotalRow('Paid:', `₹${Number(sale.paidAmount).toFixed(2)}`);
    if (Number(sale.balanceAmount) > 0) {
      addTotalRow('Balance Due:', `₹${Number(sale.balanceAmount).toFixed(2)}`, true);
    }

    // ── GST Summary Table ─────────────────────────────────────────────────────
    const gstEntries = Object.values(gstGroups).filter((g) => g.cgst > 0 || g.igst > 0);
    if (gstEntries.length > 0) {
      y += 10;
      doc.moveTo(L, y).lineTo(R, y).lineWidth(0.5).stroke();
      y += 6;
      doc.fontSize(8).font('Helvetica-Bold').text('GST SUMMARY', L, y);
      y += 14;

      doc.fontSize(7).font('Helvetica-Bold');
      doc.text('Tax Type', L,       y, { width: 100 });
      doc.text('Taxable Amt', L+100, y, { width: 100, align: 'right' });
      doc.text('Rate',        L+200, y, { width: 60, align: 'right' });
      doc.text('Tax Amount',  L+260, y, { width: 100, align: 'right' });
      y += 12;
      doc.moveTo(L, y).lineTo(L + 360, y).lineWidth(0.3).stroke();
      y += 4;

      doc.font('Helvetica').fontSize(7);
      gstEntries.forEach((g) => {
        if (g.cgst > 0) {
          doc.text(`CGST @ ${g.cgstRate}%`, L,      y, { width: 100 });
          doc.text(`₹${g.taxable.toFixed(2)}`,    L+100, y, { width: 100, align: 'right' });
          doc.text(`${g.cgstRate}%`,              L+200, y, { width: 60,  align: 'right' });
          doc.text(`₹${g.cgst.toFixed(2)}`,       L+260, y, { width: 100, align: 'right' });
          y += 12;
          doc.text(`SGST @ ${g.sgstRate}%`, L, y, { width: 100 });
          doc.text('',                       L+100, y, { width: 100, align: 'right' });
          doc.text(`${g.sgstRate}%`,         L+200, y, { width: 60,  align: 'right' });
          doc.text(`₹${g.sgst.toFixed(2)}`, L+260, y, { width: 100, align: 'right' });
          y += 12;
        }
        if (g.igst > 0) {
          doc.text(`IGST @ ${g.igstRate}%`, L,      y, { width: 100 });
          doc.text(`₹${g.taxable.toFixed(2)}`,    L+100, y, { width: 100, align: 'right' });
          doc.text(`${g.igstRate}%`,              L+200, y, { width: 60,  align: 'right' });
          doc.text(`₹${g.igst.toFixed(2)}`,       L+260, y, { width: 100, align: 'right' });
          y += 12;
        }
      });
    }

    // ── Notes ─────────────────────────────────────────────────────────────────
    if (sale.notes) {
      y += 8;
      doc.fontSize(8).font('Helvetica-Bold').text('Notes:', L, y);
      doc.font('Helvetica').text(sale.notes, L, y + 12, { width: PAGE_W });
    }

    // ── Footer ────────────────────────────────────────────────────────────────
    const footerY = doc.page.height - 50;
    doc.moveTo(L, footerY).lineTo(R, footerY).lineWidth(0.5).stroke();
    doc.fontSize(7).font('Helvetica').fillColor('#666666')
      .text('This is a computer-generated invoice. No signature required.', L, footerY + 6, { align: 'center', width: PAGE_W });

    doc.end();
  });
}

module.exports = { generateInvoicePDF };
