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

These built-in types are mapped to Julia types: `string`, `boolean`, `decimal` and `double`
(`Float64`), `integer` and `int` (`Int64`), `nonNegativeInteger` and `positiveInteger` (`UInt64`),
`dateTime`, `date`, `time` and `base64Binary`. Other built-in types, such as `float`, `long`,
`token` or `anyURI`, are not.

`decimal` is held as a `Float64`, so a decimal value with more significant digits than a `Float64`
holds loses them, and trailing zeros are not kept when it is written back.

## Restrictions

Only these facets are checked: `minInclusive`, `maxInclusive`, `minExclusive` and `maxExclusive`
on numbers and `dateTime` values, and `totalDigits` and `fractionDigits` on numbers. The string
facets `length`, `minLength`, `maxLength`, `pattern` and `enumeration` are not checked, so a
document that violates them loads, and an object that violates them is written. A `dateTime`
bound and value compare only when both have a zone offset or neither does; otherwise the check
throws an `ArgumentError`, as XML Schema leaves their order undetermined.

## Times

A `dateTime` with more than nine digits after the seconds is cut to nanoseconds, with a warning.
The difference of two `DateTimeNs` values is in nanoseconds, which span about 292 years; a longer
difference throws an `OverflowError`. Rounding below a millisecond takes only steps that divide it.
