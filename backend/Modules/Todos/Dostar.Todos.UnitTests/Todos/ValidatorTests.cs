namespace Dostar.Todos.UnitTests;

public class ValidatorTests
{
    private readonly IValidator<CreateTodoRequest> _createValidator = new CreateTodoRequestValidator();
    private readonly IValidator<UpdateTodoRequest> _updateValidator = new UpdateTodoRequestValidator();

    [Fact]
    public void CreateTodoRequest_WhenTitleIsEmpty_IsInvalid()
    {
        var result = _createValidator.Validate(new CreateTodoRequest(string.Empty));

        result.IsValid.ShouldBeFalse();
    }

    [Fact]
    public void CreateTodoRequest_WhenTitleExceedsMaxLength_IsInvalid()
    {
        var result = _createValidator.Validate(new CreateTodoRequest(new string('a', 201)));

        result.IsValid.ShouldBeFalse();
    }

    [Fact]
    public void CreateTodoRequest_WhenTitleIsValid_IsValid()
    {
        var result = _createValidator.Validate(new CreateTodoRequest("Buy milk"));

        result.IsValid.ShouldBeTrue();
    }

    [Fact]
    public void UpdateTodoRequest_WhenTitleIsEmpty_IsInvalid()
    {
        var result = _updateValidator.Validate(new UpdateTodoRequest(string.Empty, false));

        result.IsValid.ShouldBeFalse();
    }

    [Fact]
    public void UpdateTodoRequest_WhenTitleExceedsMaxLength_IsInvalid()
    {
        var result = _updateValidator.Validate(new UpdateTodoRequest(new string('a', 201), false));

        result.IsValid.ShouldBeFalse();
    }

    [Fact]
    public void UpdateTodoRequest_WhenTitleIsValid_IsValid()
    {
        var result = _updateValidator.Validate(new UpdateTodoRequest("Buy milk", true));

        result.IsValid.ShouldBeTrue();
    }
}
