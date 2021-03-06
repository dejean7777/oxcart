# XDPalette

Palette File Format

Version: 1.0 (0100h)

Copyright (c) 2009. Dejan Boras
All rights reserved.

## Introduction

   This is a binary file format for storing color palettes. It has support
for limited number of palette types. It was primarily created for use
with dImage.

The data types presented here are Pascal programming language data types.
While Pascal is not widespread, it is simple to understand, and you should
not have any major difficulties understanding the file format.

## General Specifications

### File structure

  The format stores the following data in the specified order:

Header >

- Format ID
- File Endian
- Format Version

Info >

- Author's Name
- Palette Name
- Palette Description
- Program's Name

Colors(Palette) >

- Properties
- Number of Colors(nColors)
- Color Format
- Array of colors(the palette)

### Data Types

 char - character(8-bit ASCII)

 int8 - 8 bit signed integer
 int16- 16 bit signed integer
 int32 - 32 bit signed integer

 uint8 - 32 bit unsigned integer
 uint16- 32 bit unsigned integer
 uint32 - 32 bit unsigned integer

 shortstring - Pascal style string
   First character is a byte determining the string size(0-255
   characters). There are that many characters. The characters are
   single byte. While by default their encoding is US-ASCII, it can be
   any encoding used by the program creating the palette.

### Color(Pixel) Formats

   The color formats represented in the palette are actually dImage pixel
formats. A program may use any pixel format supported by dImage. There are
no requirements to support any pixel formats in your program.

Here are some of the pixel formats:
PIXF_RGB     - 24-bit RGB(8-bits per component)
PIXF_RGBA    - 32-bit RGBA(8-bits per component)
PIXF_BGR     - 24-bit BGR(8-bits per component)
PIXF_BGRA    - 32-bit BGRA(8-bits per component)

Note that using indexed pixel formats has no meaning for the palette as
the indexed pixel formats are only used within images(and index into
a palette). If used what would the palette index to? It is illegal to use
such pixel formats,

### EGA Palettes

   EGA palettes have the RGB component values from 0 - 63. This is 4 times
less than what VGA allows. When converting a VGA to an EGA palette simply
divide(integer division) an R,G and B component with 4(assuming the
components are 8-bit). To convert a EGA to VGA palette multiply the
R,G and B component by 4.

Converting and VGA to an EGA palette will cause loss of color detail(as
you're losing 2 least significant bits of information when dividing by 4).

In the modern world there is no need for EGA palettes, but it still may
be useful to provide some support for this.

## Format Specifications

### Header

   The header identifies the file as a XDPalette file and specifies the
version of the format.

The header contains two fields:

- Format ID: array[0..4] of char = ('X', 'D', 'P', 'A', 'L');

   This is a string of 5 characters(8-bit ASCII) containing 'XDPAL'.
- File Endian: uint8
   The endian type determines the endian of the file. This is 0($0, 0x00)
   for little-endian or 255($FF, 0xFF) for big-endian.
- Format Version: uint16
   The high byte determines the major version of the format, and the low byte
   determines the lower version of the format. The current version is 0100h.
   Here the high byte will have value 1, and the lower byte will have the
   value 0.

### Info

   This part of the file contains general palette information. All fields
here are of shortstring type. If a field is omitted then it's string size
is 0.

- Author's Name
   This tells the name of the palettes author.
- Palette Name
   This is the name of the palette, set either by the author or a program.
- Palette Description
   The description of the palette.
- Program's Name
   The name of the program used to create the palette.

### Colors(Palette)

   This is the essence of the format, the actual data.

- Properties: uint32
   This field contains a bit-wise ORed sequence of boolean
   properties(0 or 1). See section 3.4 for more information.
- nColors: int32
   This field contains the total number of colors in the palette.
- Color Format: uint32
   This is actually the pixel format. It contains a valid dImage value for
   pixel formats.
- Colors
   This is the palette of colors. It contains an array of colors. The array
   has nColors number of elements. The format of each color depends on the
   Color Format field, but is usually 24 or 32-bit.

### Palette Properties

   The Properties field of the palette is a bit-wise ORed sequence of
boolean values(0 or 1).

Here are the bit-masks to access the corresponding properties and their
meaning:

- $0001 EGA Palette
   If set to 1 this means the palette is an EGA palette. See section 2.4
   for more information on EGA palettes.