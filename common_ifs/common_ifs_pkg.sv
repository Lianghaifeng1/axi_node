// Common Interfaces Package

package common_ifs_pkg;
  // dep packages
  import uvm_pkg::*;

  // Enum representing reset scheme
  typedef enum bit [1:0] {
    RstAssertSyncDeassertSync,
    RstAssertAsyncDeassertSync,
    RstAssertAsyncDeassertAsync
  } rst_scheme_e;

endpackage