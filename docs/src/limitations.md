# Limitations

XML Schema is a large recommendation, and the packages implement the part of it that the schemas
they were written for use. The list below is what is known not to work.

## Schema features

- `xs:include`, `xs:import` and `xs:redefine` are not read: a schema has to be in one file.
- A schema without a `targetNamespace` is not supported.
- `xs:list` is not read; an element that repeats, with `maxOccurs`, is. A union is read when its
  member types are written as nested `xs:simpleType` elements, not when they are named in
  `memberTypes`.
- Attribute declarations do not become fields. The attributes of an element are kept as strings in
  its `__xml_attributes` dictionary.
- Element and type names that are not valid Julia identifiers must be renamed with `mapping`; see
  [Renaming elements and types](guide/renaming.md). Without it, the module is generated but cannot
  be included.

## Built-in types

The built-in types listed in [Loading documents](guide/loading.md) are mapped to Julia types.
Others, such as `gYear`, `hexBinary` and the list types `NMTOKENS`, `IDREFS` and
`ENTITIES`, are not. The integer types such as `positiveInteger` or `negativeInteger` do not check
their sign, and `int` is held as an `Int64` rather than an `Int32`.

A reference is to a built-in type only when its prefix is bound to the XML Schema namespace, so a
schema type named like a built-in one, such as `Name`, stays a schema type. Namespaces are read
from the schema element, and the generator reserves the prefix `xs` for XML Schema: a schema that
binds `xs` to another namespace is rejected.

`decimal` is held as a `Float64`, so a decimal value with more significant digits than a `Float64`
holds loses them, and trailing zeros are not kept when it is written back.

## Restrictions

The facets checked are listed in [Types](guide/types.md#Restrictions). The others, `whiteSpace`
among them, are not. `length`, `minLength`, `maxLength` and `pattern` are checked only on types
derived from strings; on other types, such as `base64Binary`, the generator warns and leaves them
out. A pattern that subtracts a character class, such as `[a-z-[aeiou]]`, or that uses an escape
PCRE does not know, such as `\i`, `\c` or a block name like `\p{IsBasicLatin}`, makes generation
fail.

A `dateTime` bound and value compare only when both have a zone offset or neither does; otherwise
the check throws an `ArgumentError`, as XML Schema leaves their order undetermined. The same holds
for a `duration` bound and value whose order XML Schema leaves undetermined, such as `P1M` and
`P30D`: a month is shorter than 30 days in February and longer in July.

## Times

A `dateTime` with more than nine digits after the seconds is cut to nanoseconds, with a warning.
The difference of two `DateTimeNs` values is in nanoseconds, which span about 292 years; a longer
difference throws an `OverflowError`. Rounding below a millisecond takes only steps that divide it.

A `duration` with more than nine digits after the seconds is rejected. An `xs:duration` has one sign,
so writing a `Dates.CompoundPeriod` whose periods have different signs, such as `Day(1) - Hour(1)`,
throws an `ArgumentError`.
