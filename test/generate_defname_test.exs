defmodule GenerateDefnameTest do
  use ExUnit.Case

  describe "generate_defname/1" do
    test "generates defname from filename" do
      assert GenerateDefname.generate_defname("README.md") == "readme"
    end

    test "handles filenames with spaces" do
      assert GenerateDefname.generate_defname("My File.md") == "my-file"
    end

    test "handles uppercase filenames" do
      assert GenerateDefname.generate_defname("TestFile.md") == "testfile"
    end

    test "handles filenames with multiple periods" do
      assert GenerateDefname.generate_defname("file.name.md") == "file.name"
    end

    test "returns empty string for empty filename" do
      assert GenerateDefname.generate_defname("") == ""
    end
  end
end

