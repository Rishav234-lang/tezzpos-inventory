class AppError extends Error {
  constructor(message, statusCode = 500) {
    super(message);
    this.statusCode = statusCode;
  }
}

class NotFoundError extends AppError {
  constructor(resource = 'Resource') {
    super(`${resource} not found`, 404);
  }
}


class ValidationError extends AppError {
  constructor(message = 'Validation failed') {
    super(message, 400);
  }
}

class UnauthorizedError extends AppError {
  constructor(message = 'Unauthorized') {
    super(message, 401);
  }
}

class ForbiddenError extends AppError {
  constructor(message = 'Forbidden') {
    super(message, 403);
  }
}

const handleError = (reply, error) => {
  if (error instanceof AppError) {
    return reply.status(error.statusCode).send({ error: error.message });
  }
  console.error('Unhandled error:', error);
  return reply.status(500).send({ error: 'Internal server error' });
};

module.exports = { AppError, NotFoundError, ValidationError, UnauthorizedError, ForbiddenError, handleError };
