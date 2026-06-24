require('dotenv').config();
const fastify = require('fastify');
const { registerPlugins } = require('./plugins');
const { registerRoutes } = require('./routes');

const buildApp = async () => {
  const app = fastify({
    logger: true,
    trustProxy: true,
  });

  await registerPlugins(app);
  await registerRoutes(app);

  return app;
};

const start = async () => {
  const app = await buildApp();
  const port = process.env.PORT || 3000;
  const host = process.env.HOST || '0.0.0.0';

  try {
    await app.listen({ port: parseInt(port), host });
    app.log.info(`Server running on http://${host}:${port}`);
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
};

start();
