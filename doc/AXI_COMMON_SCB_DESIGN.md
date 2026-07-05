# Protocol-independent common transaction and scoreboard

## Architecture

The environment has one reference model and one scoreboard per destination
endpoint.  The reference model receives completed transactions from every
monitor, selects an adapter for the source protocol, and publishes normalized
byte accesses.  A scoreboard never depends on AXI, MEM, REG, APB, or AHB
transaction classes.

```text
upstream monitor -> reference model -> adapter -> expected endpoint scoreboard
downstream monitor -> reference model -> adapter -> actual endpoint scoreboard
```

The current implementation connects Cadence AXI `EndedCbPort` callbacks.  The
analysis FIFO associated with each monitor preserves the source port index.
Endpoint base/end addresses are stored in `axi_crossbar_cfg`; routing logic and
slave VIP memory segments consume the same configuration.

## Common transaction

`axi_crossbar_common_transaction` represents one effective byte access.  Its
mandatory functional fields are operation, byte address, and byte data.
Status, source port, destination port, and transaction ID are optional fields
controlled by `valid_mask` and the scoreboard `compare_mask`.  Beat and byte
indices and protocol name are diagnostic metadata and are not compared.

Writes generate an object only for lanes enabled by the source byte-enable or
strobe.  Reads generate one object for every requested byte.  This granularity
allows both sides to use different bus widths and permits a bridge to split or
combine transfers without changing the scoreboard.

## Adapter contract

`axi_crossbar_common_adapter_context` is configuration data, not the converter.
It identifies the monitor side and port, data width, original ID width, route,
and downstream ID encoding.  Conversion is performed by
`axi_crossbar_common_adapter::convert()`.

The implemented Cadence AXI adapter:

- Expands `Length` beats and derives bytes per beat from `Size`.
- Computes FIXED, INCR, and WRAP beat addresses.
- Maps flattened `Data[]` bytes to effective byte addresses.
- Applies `StrobeArray[]` to writes.
- Maps read `TransfersResp[]` and write `Resp` to a common status.
- Restores the source master and original ID from the downstream extended ID.

A future MEM or REG interface needs an adapter for each distinct monitor
transaction format, not one class per slave instance.  Multiple endpoints that
use the same transaction type can share one adapter object.  Such adapters only
need to expand address, data, byte-enable, direction, and optional error fields
into common byte transactions; the scoreboard remains unchanged.

## Scoreboard matching

Each endpoint scoreboard owns expected and actual pending pools indexed by
operation and byte address.  On arrival, it searches the opposite pool for a
full payload match under the configured comparison mask.  A match removes both
objects; otherwise the object remains pending.  This is symmetric, so monitor
callback order and reordering between independent AXI IDs do not matter.

At report phase, objects with the same key but different payloads are reported
as mismatches.  Remaining one-sided objects are reported as missing expected or
missing actual transactions.  Normal completion requires no mismatch and no
pending object.

When a downstream protocol removes AXI ID and source information, those fields
must be disabled in that endpoint's comparison mask.  The scoreboard then
checks the multiset of byte accesses, but cannot prove causal association with
a particular master.  Ordering and causality after ID removal require protocol
assertions or a downstream debug tag.

## Compatibility

Supported normalization includes AXI single and multi-beat transactions,
FIXED/INCR/WRAP bursts, narrow and unaligned accesses, sparse write strobes,
multiple masters and destinations, multiple outstanding IDs, width conversion,
and AXI-to-MEM or AXI-to-REG splitting and combining.

The common layer does not implement memory state, register side effects,
clear-on-read or write-one-to-clear behavior, coherence, AXI5 atomics, or
cycle-level channel checking.  Cadence VIP remains responsible for protocol
timing.  Mid-transaction reset requires flushing pending objects.  Unmapped
accesses that terminate locally require a separate error endpoint scoreboard.

## Checker regression

`axi_crossbar_test_scb_unit` sends three same-address expected bytes in forward
order and the actual bytes in reverse order.  It also directly verifies that a
different payload is rejected with a non-empty diagnostic.

`axi_crossbar_test_stress` covers FIXED/INCR/WRAP, burst lengths 1/2/4/5/7/8/16,
BYTE/HALFWORD/WORD sizes, unaligned starts, sparse strobes 0x5/0xa, both masters,
both slaves, and 12 concurrent writes followed by 12 concurrent reads with
distinct IDs.  Its minimum accepted byte counts are 610 for slave0 and 298 for
slave1.
