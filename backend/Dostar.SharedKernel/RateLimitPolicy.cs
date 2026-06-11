namespace Dostar.SharedKernel;

public static class RateLimitPolicy
{
    public const string Strict = "strict";
    public const string TestPartition = "test";
    public const string UnknownIpPartition = "unknown";

    public const int GlobalPermitLimit = 100;
    public const int StrictPermitLimit = 10;
    public const int NoQueueLimit = 0;
    public static readonly TimeSpan RateLimitWindow = TimeSpan.FromMinutes(1);
}
