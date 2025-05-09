Few weeks back I needed a, ascii value of a photo. So I AI for generating it.
So I was wondering if I could build it myself with the following 'rules'

- Pure ruby, no deps.
- No code generation by AI, LLM etc...
- Can use AI for a guidance (see below)
- Use [docs](https://www.w3.org/TR/png/#11IHDR) for more information about PNG encoding/decoing

---

# PNG to ASCII Converter in Ruby (No Gems)

## Overview

This project parses a PNG image, reconstructs the pixel data manually from the raw format, and converts it into ASCII art — all using pure Ruby.

---

## 🧩 1. PNG Chunk Parsing (Est. 4–6 hours)

### Step-by-Step:

#### a. Read and Validate the PNG Signature (15 mins)

* Read the first 8 bytes.
* Confirm it matches: `89 50 4E 47 0D 0A 1A 0A`.

#### b. Loop Through Chunks (1–2 hours)

* Continue reading until the `IEND` chunk is reached.

* For each chunk:

  * Read 4 bytes → chunk length (big-endian)
  * Read 4 bytes → chunk type (`IHDR`, `IDAT`, etc.)
  * Read `length` bytes → chunk data
  * Read 4 bytes → CRC (can be skipped)

* Save:

  * `IHDR` → Parse its 13 bytes to extract:

    * Width
    * Height
    * Bit depth
    * Color type
    * Compression method
    * Filter method
    * Interlace method
  * `IDAT` chunks → Concatenate all their data into a single compressed blob

#### c. Decompress Image Data (30 mins)

* Use `Zlib::Inflate` to decompress the concatenated `IDAT` data.
* Result is a sequence of scanlines:

  ```
  [FilterByte][ScanlineData][FilterByte][ScanlineData]...
  ```

---

## 🧪 2. Reversing PNG Filters (Est. 6–10 hours)

After decompression, each image row begins with a filter byte (0–4), followed by the filtered pixel data.

### Step-by-Step:

#### a. Understand Scanline Layout (1–2 hours)

* Calculate bytes per pixel (bpp) from IHDR:

  * RGB → 3
  * RGBA → 4
* Row size = width × bpp

#### b. Loop Over Rows and Extract Filter Type (30 mins)

* For each row:

  * Read the first byte = filter type
  * The rest of the row = filtered data

#### c. Implement Reverse Filter Functions (4–6 hours)

You’ll need to implement five reverse filter functions:

| Filter Type | Name    | Description                                            |
| ----------- | ------- | ------------------------------------------------------ |
| 0           | None    | No change                                              |
| 1           | Sub     | Each byte is modified by the byte to its left          |
| 2           | Up      | Each byte is modified by the byte directly above       |
| 3           | Average | Each byte is modified by the average of left and above |
| 4           | Paeth   | Complex predictor using left, above, and top-left      |

* Must operate byte-by-byte across rows
* Carefully handle edge cases:

  * First pixel in a row (no "left")
  * First row (no "above")
* Maintain:

  * `prev_row` buffer (for Up/Average/Paeth)
  * `current_row` being reconstructed (used for left values)

---

## 🎨 3. Convert Pixels to ASCII (Est. 2–4 hours)

### Step-by-Step:

* Loop over each pixel:

  * Convert RGB to grayscale (e.g., `0.3*R + 0.59*G + 0.11*B`)
  * Normalize grayscale to a value between 0–1 or 0–255
  * Map that value to a character from a predefined ASCII gradient (e.g., `@#%xo;:,. `)
* Optionally:

  * Rescale the image to a smaller width
* Output the ASCII to:

  * The terminal
  * A text file

---

## ⏱️ Estimated Total Time: \~12–20 Hours

### If You’re Experienced With:

* Binary data parsing
* Image formats
* Ruby I/O and bitwise operations

You may complete it in **\~12 hours**.

### If You’re New to This Level of Detail:

Expect closer to **20 hours**, especially for debugging filter handling.

---

## 💡 Optional Shortcuts (If You Get Stuck)

* Use pre-decoded raw RGB dumps (e.g., via ImageMagick) for testing the ASCII logic.
* Start with PNGs using **Filter Type 0 only** (no filtering).
* Test on artificially simple PNGs (e.g., 2x2 pixels).

---

Let me know if you'd like a checklist version too!
