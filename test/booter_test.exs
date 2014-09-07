defmodule BooterTest do
  use ExUnit.Case
  import Booter, only: :functions
  alias Booter.Step
  alias Booter.Error

  defmodule BareModule do
    Module.register_attribute __MODULE__, :boot_step, accumulate: true, persist: true
    @boot_step %Step{name: :bare, description: "Bare Step"}
    @boot_step %Step{name: :bare_two, description: "Second Bare Step"}
  end

  defmodule MacroModule do
    use Booter
    boot_step skip: true
    boot_step :macro_two, skip: true
    boot_step :macro_three, "description", skip: true
  end

  test "module_steps/1 on a bare module" do
    steps = module_steps(BareModule)
    assert is_list steps
    assert Enum.count(steps) == 2
    bare = Enum.at(steps, 0)
    assert bare.__struct__ == Step
  end

  test "module_steps/1 on a module using boot_step/3 macro" do
    steps = module_steps(MacroModule)
    assert is_list steps
    assert Enum.count(steps) == 3

    # boot_step/3 with (nil, nil, options)
    macro_one = Enum.at(steps, 0)
    assert macro_one.__struct__ == Step
    assert Keyword.keys(macro_one.source_file) == [:file, :line]
    assert macro_one.name == MacroModule
    assert macro_one.skip
    refute macro_one.description

    # boot_step/3 with (name, nil, options)
    macro_two = Enum.at(steps, 1)
    assert macro_two.name == :macro_two
    assert macro_two.skip
    refute macro_two.description

    # boot_step/3 with (name, description, options)
    macro_three = Enum.at(steps, 2)
    assert macro_three.name == :macro_three
    assert macro_three.description == "description"
    assert macro_three.skip
  end

  test "modules_steps/1 with given list of module" do
    steps = modules_steps([BareModule, MacroModule])
    assert is_list steps
    assert Enum.count(steps) == 5
  end

  defmodule Dependencies do
    use Booter

    boot_step :unicorn, requires: :rainbow
    boot_step :moon, requires: :planet
    boot_step :sky, requires: :planet, enables: :earth
    boot_step :earth, "Earth is vivable!", []
    boot_step :clouds, requires: :planet, enables: :earth
    boot_step :rainbow, requires: :earth
    boot_step :poneys, requires: :unicorn
    boot_step :planet, "Just a rock :(", []
  end

  test "ordered_steps/1" do
    unordered_steps = modules_steps([Dependencies])
    steps = ordered_steps(unordered_steps)
    steps_names = Enum.map(steps, fn(s) -> s.name end)
    assert is_list steps
    assert Enum.count(unordered_steps) == Enum.count(steps)
    assert steps_names == [:planet, :clouds, :sky, :earth, :rainbow, :unicorn, :moon, :poneys]
  end

  defmodule DupeDeps do
    use Booter

    boot_step :rainbow, "RAINBOWSSSSSSS", []
  end

  test "ordered_steps/1 with duplicate steps" do
    unordered_steps = modules_steps([Dependencies, DupeDeps])
    assert_raise Error.DuplicateStep, fn -> ordered_steps(unordered_steps) end
  end

  defmodule UnknownDep do
    use Booter

    boot_step :kim_jung, requires: :double_rainbow
  end

  test "ordered_steps/1 with an unknown dependency" do
    unordered_steps = modules_steps([Dependencies, UnknownDep])
    assert_raise Error.UnknownDependency, fn -> ordered_steps(unordered_steps) end
  end

  defmodule CyclicDep do
    use Booter

    boot_step :magic, requires: :flying_unicorn
    boot_step :flying_unicorn, requires: :magic
  end

  test "ordered_steps/1 with a cyclic dependency" do
    unordered_steps = modules_steps([Dependencies, CyclicDep])
    assert_raise Error.CyclicDependency, fn -> ordered_steps(unordered_steps) end
  end

  defmodule BootMe do
    use Booter

    boot_step :great_question, mfa: {List, :to_string, ['what is the meaning of life']}
    boot_step :forty_two, mfa: {Integer, :to_string, [42]}, requires: :great_question
  end

  test "boot!/1" do
    steps = module_steps(BootMe)
    return = boot!([BootMe])
    assert return == [{:ok, Enum.at(steps, 0), "what is the meaning of life"}, {:ok, Enum.at(steps, 1), "42"}]
  end

  defmodule BootSkip do
    use Booter
    boot_step :skipme, mfa: {String, :to_integer, ["lol, nope"]}, skip: "gonna fail"
  end

  test "boot!/1 with skippable step" do
    steps = module_steps(BootSkip)
    return = boot!([BootSkip])
    assert return == [{:skip, Enum.at(steps, 0), "gonna fail"}]
  end

  defmodule BootRaise do
    use Booter
    boot_step :fail_hard, mfa: {String, :to_integer, ["lol, nope"]}
  end

  test "boot!/1 with failing step" do
    assert_raise Error.StepError, fn -> Booter.boot!([BootRaise]) end
  end

  defmodule BootCatch do
    use Booter
    boot_step :fail_hard_catch_me, mfa: {String, :to_integer, ["lol, nope"]}, catch: true
  end

  test "boot!/1 with catchable step" do
    steps = module_steps(BootCatch)
    return = boot!([BootCatch])
    assert return == [{:error, Enum.at(steps, 0), %ArgumentError{message: "argument error"}}]
  end

  defmodule BootWithoutFun do
    use Booter
    boot_step :no_fun, []
  end

  test "boot!/1 with a step without mfa" do
    steps = module_steps(BootWithoutFun)
    return = boot!([BootWithoutFun])
    assert return == [{:no_mfa, Enum.at(steps, 0), nil}]
  end

end
