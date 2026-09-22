---
name: rwanda-identifiers
description: >-
  Akokuntaro Coding Skills — the canonical Rwanda phone number and National ID
  rules. Apply whenever a field holds a Rwandan mobile number or an NID: validation,
  normalisation, storage, lookup and de-duplication, Joi/zod form schemas, seeds,
  imports and cleanup scripts. Covers the input spellings that must be accepted, the
  single stored form, the 16-digit NID rule with its birth-year window, and the
  optional-field trap. Pair it with coding-principles and the stack skill.
---

# Rwanda identifiers — phone numbers & National ID

Two fields turn up in every one of these apps, and each has exactly one correct rule.
Copy the rule into one shared helper per app; never re-derive it per form.

## Phone — Rwandan mobile

Accept every spelling a person actually types: `+250788123456`, `250788123456`,
`788123456`, `0788123456`, with spaces anywhere in them.

Normalise first, then validate:

1. Strip all whitespace.
2. Strip a leading `+250` or `250`.
3. If what remains starts with `7`, prefix `0`.
4. Valid **iff** the result matches `^07\d{8}$`.

```ts
export const normalizeRwandaPhone = (value: string): string => {
  let phone = value.replace(/\s+/g, '');
  if (phone.startsWith('+250')) phone = phone.slice(4);
  else if (phone.startsWith('250')) phone = phone.slice(3);
  return phone.startsWith('7') ? `0${phone}` : phone;
};

export const isValidRwandaPhone = (value?: string | null): boolean =>
  !!value && /^07\d{8}$/.test(normalizeRwandaPhone(value));
```

**Store and compare the normalised `07XXXXXXXX` form, always.** One number typed four
ways is four rows and four accounts, and a lookup by raw input misses the person who is
already there. If an outbound gateway wants `+250…` (SMS), convert at that call site —
never keep a second spelling in the column.

## National ID — Rwandan NID

- Exactly 16 digits, first digit `1`, `2` or `3`: `^[123]\d{15}$`.
- Digits 2–5 are the birth year, and must fall between **1930 and 2010** inclusive. The
  NID is issued at about 16, so the maximum tracks `currentYear - 16` — bump it as years
  advance, in every copy at once.
- Strip whitespace before validating; the stored form is a bare 16-digit string.

```ts
export const NID_MIN_BIRTH_YEAR = 1930;
export const NID_MAX_BIRTH_YEAR = 2010;
export const NATIONAL_ID_ERROR =
  'National ID must be 16 digits, start with 1, 2 or 3, and encode a birth year between 1930 and 2010';

export const normalizeNationalId = (value: string): string => value.replace(/\s+/g, '');

export const isValidNationalId = (value?: string | null): boolean => {
  if (!value) return false;
  const nid = normalizeNationalId(value);
  if (!/^[123]\d{15}$/.test(nid)) return false;
  const year = Number(nid.slice(1, 5));
  return year >= NID_MIN_BIRTH_YEAR && year <= NID_MAX_BIRTH_YEAR;
};
```

## The parts that get missed

- **Normalise before storing AND before comparing.** Only normalising on write still lets
  a search, an import match or a duplicate check fail on the same person typed differently.
- **Validate on both sides.** The client validates to give a message; the server validates
  because that is what keeps the table clean. Seeds, imports and one-off scripts go through
  the same helper — they are the usual source of the bad rows.
- **An optional field is "valid if present", never "required".** Blank, `''` and `null`
  pass; a supplied value must be valid. In Joi that is `schema.allow('', null).optional()` —
  **not** `optionalOrEmpty()`, whose `Joi.string().allow('')` branch matches any string and
  skips the check entirely. In zod, `.refine(v => v === '' || isValid(v)).optional()`.
- **Export the error message as a constant** and use it on both sides, so the form and the
  API complain in the same sentence.
