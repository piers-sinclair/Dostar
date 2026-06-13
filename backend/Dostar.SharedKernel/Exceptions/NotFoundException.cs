namespace Dostar.SharedKernel.Exceptions;

public sealed class NotFoundException(string message) : Exception(message);
