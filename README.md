# Fast web deploy
  Blazingly fast deploy of markdown files as html.
  This project aims to transform a directory of files into coherent interconnected static set of html files.


## Blog deploy (Finished)
  blog-deploy.exs aims to build a linked graph of markdown files into a coherent interconnected static set of html files.

### Extra fetures
  - Parallel processing
  - Automatic conversion of markdown linking into html local linking (functional urls)
  - (Not standard md) transformation of flagged content into summary/details html

## Git deploy (WIP)
  git-deploy.exs aims to build a list of git directories and a web interface of each target repository as done in . But in parallel execution and without git hooks.
