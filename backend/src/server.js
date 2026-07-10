const path = require('path');
const fs = require('fs');
const dotenv = require('dotenv');

const rootEnvPath = path.resolve(__dirname, '../../.env');

const stripWrappedQuotes = (value) => {
  if (!value) return value;
  return value.replace(/^['"]|['"]$/g, '');
};

const loadUtf16Env = (filePath) => {
  if (!fs.existsSync(filePath)) return;

  const raw = fs.readFileSync(filePath, 'utf16le');
  for (const line of raw.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;

    const separatorIndex = trimmed.indexOf('=');
    if (separatorIndex <= 0) continue;

    const key = trimmed.slice(0, separatorIndex).trim();
    const value = stripWrappedQuotes(trimmed.slice(separatorIndex + 1).trim());
    if (key && process.env[key] === undefined) {
      process.env[key] = value;
    }
  }
};

dotenv.config();
dotenv.config({ path: rootEnvPath });

if (!process.env.DATABASE_URL || process.env.DATABASE_URL.startsWith('"')) {
  loadUtf16Env(rootEnvPath);
}
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
