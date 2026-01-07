## JDcloud Fork

This fork of [jdcloud-sdk-go](https://github.com/jdcloud-api/jdcloud-sdk-go) is made for lego.

This is a special fork:
- only 2 packages are kept `core` and `services/domainservice`
- contains no other changes to the original code than the imports and method signatures.

The methods of the structure `DomainserviceClient` are converted to functions which use `DomainserviceClient` as a parameter.

The goal is to break the link between the `DomainserviceClient` structure and the other structures to reduce the binary size.

This automatic approach for the fork is possible because the `jdcloud-sdk-go` API client is 100 % generated.

**This fork is not intended for use outside of lego, and it can be deleted/archived at any time.**

The code of the module is inside the branch [`modifiedclient`](https://github.com/go-acme/jdcloud-sdk-go/tree/modifiedclient).

### Maintenance

The script to update the fork is `update.sh`.

The env var `LIB_VERSION` must be updated to reference the targeted version.

I update the branch "manually" by calling the script regularly.
