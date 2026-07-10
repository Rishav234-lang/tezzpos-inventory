const GENERAL_CATEGORY_NAME = 'General';

function isGeneralCategoryName(name) {
  return (name || '').trim().toLowerCase() ===
    GENERAL_CATEGORY_NAME.toLowerCase();
}

async function ensureGeneralCategory(prisma, companyId) {
  const existing = await prisma.category.findFirst({
    where: {
      companyId,
      name: {
        equals: GENERAL_CATEGORY_NAME,
        mode: 'insensitive',
      },
    },
  });

  if (existing) return existing;

  return prisma.category.create({
    data: {
      companyId,
      name: GENERAL_CATEGORY_NAME,
      description: 'Default category for new products',
      status: 'ACTIVE',
    },
  });
}

module.exports = {
  GENERAL_CATEGORY_NAME,
  ensureGeneralCategory,
  isGeneralCategoryName,
};
