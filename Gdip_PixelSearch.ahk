;***********************************************************************************************************************
;   ____     _ _          ____  _          _ ____                      _      ____  
;  / ___| __| (_)_ __    |  _ \(_)_  _____| / ___|  ___  __ _ _ __ ___| |__  / /\ \ 
; | |  _ / _` | | '_ \   | |_) | \ \/ / _ \ \___ \ / _ \/ _` | '__/ __| '_ \| |  | |
; | |_| | (_| | | |_) |  |  __/| |>  <  __/ |___) |  __/ (_| | | | (__| | | | |  | |
;  \____|\__,_|_| .__/___|_|   |_/_/\_\___|_|____/ \___|\__,_|_|  \___|_| |_| |  | |
;               |_| |_____|                                                  \_\/_/ 
; 
;***********************************************************************************************************************
/**
 * @author prodbyichigo, MasterFocus (Some methods inspired)
 *
 * @function Gdip_PixelSearch
 * @description
 * Searches a GDI+ bitmap (`pBitmapHaystack`) for a pixel whose ARGB value matches
 * `pColor`, with support for eight directional search modes and optional color
 * variation tolerance.
 *
 * @param {Ptr} pBitmapHaystack - Pointer to the GDI+ bitmap to scan.
 * @param {Integer} pColor - The target ARGB color value.
 * @param {Integer} [SearchDir=1] - Search direction.  
 * Directions (1–8):
 *   **Vertical preference**  
 *     1 = top → left → right → bottom (default)  
 *     2 = bottom → left → right → top  
 *     3 = bottom → right → left → top  
 *     4 = top → right → left → bottom  
 *   **Horizontal preference**  
 *     5 = left → top → bottom → right  
 *     6 = left → bottom → top → right  
 *     7 = right → bottom → top → left  
 *     8 = right → top → bottom → left
 *
 * @param {Integer} [int_levelOfVariation=0] - Allowed tolerance between pixel and target
 *        color (0–255).
 *
 * @param {Integer} &posX - Output variable for the located pixel’s X coordinate.
 * @param {Integer} &posY - Output variable for the located pixel’s Y coordinate.
 *
 * @returns {Integer}
 * Returns:
 *   0      → pixel found  
 *   -1     → no matching pixel  
 *   -1001  → invalid bitmap dimensions  
 *   other negative values → internal error
 */

Gdip_PixelSearch(pBitmapHaystack, pColor, SearchDir := 1, int_levelOfVariation := 0, &posX := 0, &posY := 0) {
    Gdip_GetImageDimensions(pBitmapHaystack, &hWidth, &hHeight)

    if hWidth <= 0 OR hHeight <= 0
        return -1001

    if !IsInteger(int_levelOfVariation) OR int_levelOfVariation < 0 OR int_levelOfVariation > 255
        return -1002

    Gdip_LockBits(pBitmapHaystack, 0, 0, hWidth, hHeight, &Stride, &Scan0, &BitmapData)

    minR := minG := minB := maxR := maxG := maxB := 0

    if int_levelOfVariation {
        targetColor := pColor + 0
        targetR := (targetColor >> 16) & 0xFF
        targetG := (targetColor >> 8) & 0xFF
        targetB := targetColor & 0xFF
        
        minR := Max(0, targetR - int_levelOfVariation)
        maxR := Min(255, targetR + int_levelOfVariation)
        minG := Max(0, targetG - int_levelOfVariation)
        maxG := Min(255, targetG + int_levelOfVariation)
        minB := Max(0, targetB - int_levelOfVariation)
        maxB := Min(255, targetB + int_levelOfVariation)
    }
    
    iX := 1, stepX := 1, iY := 1, stepY := 1
    Modulo := Mod(SearchDir, 4)
    
    if (Modulo > 1)
        iY := 2, stepY := 0
    
    if !Mod(Modulo, 3)
        iX := 2, stepX := 0

    if (SearchDir > 4) {
        P := "X", N := "Y"
        PMax := hWidth, NMax := hHeight
    } else {
        P := "Y", N := "X"
        PMax := hHeight, NMax := hWidth
    }
    
    PStart := (iY == 1 && P == "Y") || (iX == 1 && P == "X") ? 0 : (P == "Y" ? hHeight - 1 : hWidth - 1)
    NStart := (iY == 1 && N == "Y") || (iX == 1 && N == "X") ? 0 : (N == "Y" ? hHeight - 1 : hWidth - 1)
    PStep := (stepY == 1 && P == "Y") || (stepX == 1 && P == "X") ? 1 : -1
    NStep := (stepY == 1 && N == "Y") || (stepX == 1 && N == "X") ? 1 : -1
    
    PPos := PStart
    loop PMax {
        NPos := NStart
        loop NMax {
            x := (P == "X" ? PPos : NPos)
            y := (P == "Y" ? PPos : NPos)
            
            pixel := NumGet(Scan0 + (y * Stride) + (x * 4), "UInt") & 0xFFFFFF
            
            if int_levelOfVariation {
                r := (pixel >> 16) & 0xFF
                g := (pixel >> 8) & 0xFF
                b := pixel & 0xFF
                if (r >= minR && r <= maxR && g >= minG && g <= maxG && b >= minB && b <= maxB) {
                    posX := x
                    posY := y
                    Gdip_UnlockBits(pBitmapHaystack, &BitmapData)
                    return 1
                }
            } else {
                if (pixel = (pColor & 0xFFFFFF)) {
                    posX := x
                    posY := y
                    Gdip_UnlockBits(pBitmapHaystack, &BitmapData)
                    return 1
                }
            }
            
            NPos += NStep
        }
        PPos += PStep
    }
    
    Gdip_UnlockBits(pBitmapHaystack, &BitmapData)
    return 0
}
