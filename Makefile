acct1:
	@git switch -C acct1/$(or $(b),work) || git switch acct1/$(or $(b),work); echo "acct1/* branch active"
acct2:
	@git switch -C acct2/$(or $(b),work) || git switch acct2/$(or $(b),work); echo "acct2/* branch active"
acct3:
	@git switch -C acct3/$(or $(b),work) || git switch acct3/$(or $(b),work); echo "acct3/* branch active"
