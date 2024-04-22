defmodule TransformLinksTest do
  use ExUnit.Case

  import TransformLinks, only: [transform_links: 1, generate_defname: 1]

  test "transforms links correctly" do
    input = "This is a [[link1]] and this is [[link2]]."

    expected_output =
      "This is a <a href=link1.html>link1 </a> and this is <a href=link2.html>link2 </a>."

    actual_output = transform_links(input)

    assert actual_output == expected_output
  end

  test "generates definition name correctly" do
    file = "My File.md"
    expected_defname = "my-file"

    actual_defname = generate_defname(file)

    assert actual_defname == expected_defname
  end
end
