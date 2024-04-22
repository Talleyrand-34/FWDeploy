defmodule DeployMdTest do
  use ExUnit.Case

  describe "process_md_file/1" do
    test "transforms Markdown to HTML" do
      markdown_path = "test/md/index.md"
      expected_html_path = "test/html/index_real.html"
      {:ok, html_content} = DeployMd.md_to_html(markdown_path)

      expected_html_content = File.read!(expected_html_path)

      assert html_content == expected_html_content
    end
  end
end
