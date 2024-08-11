local g = vim.g

g.ale_linters = {
	javascript = {'eslint', 'prettier'},
	lua = {'lua-language-server'},
	terraform = {'terraform-ls', 'tflint'},
	typescript = {'eslint', 'prettier'},
	yaml = {'yaml-language-server','yamlfmt','yamllint'}
}

g.ale_fixers = {
	javascript = {'eslint', 'prettier'},
	terraform = {'terraform-fmt-fixer'},
	typescript = {'eslint', 'prettier'}
}

g.ale_fix_on_save = 1
