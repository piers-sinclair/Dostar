namespace Dostar.Todos.UnitTests;

public class CreateTodoRequestValidatorTests
{
    private readonly Fixture _fixture = new();
    private readonly CreateTodoRequestValidator _sut = new();

    [Fact]
    public async Task Validate_WhenTitleIsValid_ReturnsValid()
    {
        var request = _fixture.Create<CreateTodoRequest>();

        var result = await _sut.ValidateAsync(request);

        result.IsValid.ShouldBeTrue();
    }

    [Fact]
    public async Task Validate_WhenTitleIsEmpty_ReturnsInvalid()
    {
        var request = _fixture.Build<CreateTodoRequest>().With(x => x.Title, string.Empty).Create();

        var result = await _sut.ValidateAsync(request);

        result.IsValid.ShouldBeFalse();
        result.Errors.ShouldContain(e => e.PropertyName == nameof(CreateTodoRequest.Title));
    }

    [Fact]
    public async Task Validate_WhenTitleExceedsMaxLength_ReturnsInvalid()
    {
        var request = _fixture.Build<CreateTodoRequest>().With(x => x.Title, new string('a', 201)).Create();

        var result = await _sut.ValidateAsync(request);

        result.IsValid.ShouldBeFalse();
        result.Errors.ShouldContain(e => e.PropertyName == nameof(CreateTodoRequest.Title));
    }

    [Fact]
    public async Task Validate_WhenTitleIsExactlyMaxLength_ReturnsValid()
    {
        var request = _fixture.Build<CreateTodoRequest>().With(x => x.Title, new string('a', 200)).Create();

        var result = await _sut.ValidateAsync(request);

        result.IsValid.ShouldBeTrue();
    }
}
