import SwiftUI
import Vision
import VisionKit

// MARK: - Receipt Metadata Model
/// Contains extracted information from a scanned receipt
struct ReceiptMetadata: Sendable {
    let merchantName: String?
    let date: Date?
    let totalAmount: Decimal?
    let currencyCode: String?
    let rawText: String
    
    /// Returns true if at least one meaningful field was extracted
    var hasData: Bool {
        merchantName != nil || date != nil || totalAmount != nil
    }
    
    /// Formatted total amount string
    var formattedTotal: String? {
        guard let amount = totalAmount else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode ?? "INR"
        return formatter.string(from: amount as NSDecimalNumber)
    }
}

// MARK: - Receipt Processor Errors
enum ReceiptProcessorError: LocalizedError {
    case imageConversionFailed
    case noDocumentFound
    case processingFailed(String)
    case unsupportedOS
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image for processing"
        case .noDocumentFound:
            return "No document content found in image"
        case .processingFailed(let message):
            return "Processing failed: \(message)"
        case .unsupportedOS:
            return "This feature requires iOS 26 or later"
        }
    }
}

// MARK: - Receipt Processor Actor
/// Thread-safe processor for extracting receipt data using iOS 26 Vision APIs
actor ReceiptProcessor {
    
    // MARK: - Singleton
    static let shared = ReceiptProcessor()
    
    private init() {}
    
    // MARK: - Main Processing Entry Point
    /// Process a scanned receipt image and extract metadata
    /// - Parameter image: The UIImage from the document scanner
    /// - Returns: Extracted receipt metadata
    func process(image: UIImage) async throws -> ReceiptMetadata {
        guard let cgImage = image.cgImage else {
            print("❌ [ReceiptProcessor] Failed to convert UIImage to CGImage")
            throw ReceiptProcessorError.imageConversionFailed
        }
        
        print("📷 [ReceiptProcessor] ============================================")
        print("📷 [ReceiptProcessor] Starting receipt processing...")
        print("📷 [ReceiptProcessor] Image dimensions: \(Int(image.size.width))x\(Int(image.size.height))")
        
        // Check iOS version availability
        if #available(iOS 26.0, *) {
            // Step 1: Check for lens smudge
            print("🔍 [ReceiptProcessor] Step 1: Checking for lens smudge...")
            await checkLensSmudge(cgImage: cgImage)
            
            // Step 2: Run document recognition
            print("📄 [ReceiptProcessor] Step 2: Running document recognition...")
            return try await processWithVision(cgImage: cgImage)
        } else {
            print("❌ [ReceiptProcessor] iOS 26+ required for document recognition")
            throw ReceiptProcessorError.unsupportedOS
        }
    }
    
    // MARK: - iOS 26+ Vision Processing
    @available(iOS 26.0, *)
    private func processWithVision(cgImage: CGImage) async throws -> ReceiptMetadata {
        print("📄 [ReceiptProcessor] Creating RecognizeDocumentsRequest...")
        let documentRequest = RecognizeDocumentsRequest()
        
        let observations: [DocumentObservation]
        do {
            print("📄 [ReceiptProcessor] Performing document recognition on image...")
            observations = try await documentRequest.perform(on: cgImage)
            print("✅ [ReceiptProcessor] Document recognition completed successfully")
        } catch {
            print("❌ [ReceiptProcessor] Document recognition failed: \(error.localizedDescription)")
            throw ReceiptProcessorError.processingFailed(error.localizedDescription)
        }
        
        print("📄 [ReceiptProcessor] Found \(observations.count) document observation(s)")
        
        guard let observation = observations.first else {
            print("❌ [ReceiptProcessor] No document observations found in the image")
            throw ReceiptProcessorError.noDocumentFound
        }
        
        // Step 3: Extract data from observation
        print("📊 [ReceiptProcessor] Step 3: Extracting metadata from document...")
        let metadata = extractMetadata(from: observation)
        
        // Log extracted data summary
        print("📊 [ReceiptProcessor] ============================================")
        print("📊 [ReceiptProcessor] EXTRACTION SUMMARY:")
        if let merchant = metadata.merchantName {
            print("   🏪 Merchant: \"\(merchant)\"")
        } else {
            print("   🏪 Merchant: (not found)")
        }
        if let date = metadata.date {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            print("   📅 Date: \(formatter.string(from: date))")
        } else {
            print("   📅 Date: (not found)")
        }
        if let total = metadata.formattedTotal {
            print("   💰 Total: \(total)")
        } else {
            print("   💰 Total: (not found)")
        }
        print("   📝 Raw text length: \(metadata.rawText.count) characters")
        print("📊 [ReceiptProcessor] ============================================")
        
        return metadata
    }
    
    // MARK: - Lens Smudge Detection
    @available(iOS 26.0, *)
    private func checkLensSmudge(cgImage: CGImage) async {
        do {
            print("🔍 [ReceiptProcessor] Creating DetectLensSmudgeRequest...")
            let smudgeRequest = DetectLensSmudgeRequest()
            
            print("🔍 [ReceiptProcessor] Performing smudge detection...")
            let result = try await smudgeRequest.perform(on: cgImage)
            
            // SmudgeObservation is a single result with confidence property
            let confidence = result.confidence
            let status = confidence > 0.9 ? "⚠️ WARNING: LENS IS DIRTY!" : "✅ OK"
            print("🔍 [ReceiptProcessor] Smudge confidence: \(String(format: "%.2f", confidence)) - \(status)")
            
            if confidence > 0.9 {
                print("⚠️⚠️⚠️ [ReceiptProcessor] SMUDGE WARNING: Camera lens appears dirty!")
                print("⚠️⚠️⚠️ [ReceiptProcessor] Image quality may be significantly affected.")
                print("⚠️⚠️⚠️ [ReceiptProcessor] Please clean your camera lens and try again.")
            }
        } catch {
            // Non-critical - just log and continue
            print("⚠️ [ReceiptProcessor] Lens smudge check failed (non-critical): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Metadata Extraction
    @available(iOS 26.0, *)
    private func extractMetadata(from observation: DocumentObservation) -> ReceiptMetadata {
        var extractedDate: Date?
        var extractedAmount: Decimal?
        var extractedCurrency: String?
        var merchantName: String?
        
        // Get the document container
        let document = observation.document
        
        // Get the full transcript text from the document
        let rawText = document.text.transcript
        
        print("📝 [ReceiptProcessor] Raw text extracted from document:")
        print("   ---BEGIN RAW TEXT (first 500 chars)---")
        print("   \(String(rawText.prefix(500)))")
        print("   ---END RAW TEXT---")
        
        // Split into lines for analysis
        let lines = rawText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        print("📝 [ReceiptProcessor] Document has \(lines.count) non-empty lines")
        
        // Extract merchant name using smart detection
        merchantName = extractMerchantName(from: lines, rawText: rawText)
        if let merchant = merchantName {
            print("🏪 [ReceiptProcessor] Detected merchant: \"\(merchant)\"")
        }
        
        // ============================================
        // STEP A: ALWAYS run TOTAL-line detection FIRST
        // This is the most reliable way to find the actual total
        // ============================================
        print("💰 [ReceiptProcessor] Step A: Running TOTAL-line detection (priority method)...")
        let totalLineResult = extractTotalFromReceipt(rawText)
        if let amount = totalLineResult.amount {
            extractedAmount = amount
            extractedCurrency = totalLineResult.currency
            print("✅ [ReceiptProcessor] Found total via TOTAL-line: \(amount) \(extractedCurrency ?? "unknown")")
        } else {
            print("⚠️ [ReceiptProcessor] No TOTAL-line found, will check Vision API amounts...")
        }
        
        // ============================================
        // STEP B: Process Vision API detectedData
        // For dates: use directly
        // For amounts: only use if TOTAL-line detection failed, and filter promotional amounts
        // ============================================
        let detectedDataCount = document.text.detectedData.count
        print("🔎 [ReceiptProcessor] Processing \(detectedDataCount) detected data items from Vision API...")
        
        // Collect Vision amounts for potential use
        var visionAmounts: [(amount: Decimal, currency: String, isPromotional: Bool)] = []
        
        for (index, dataMatch) in document.text.detectedData.enumerated() {
            switch dataMatch.match.details {
            case .calendarEvent(let event):
                print("� [ReceiptProcessor] Item \(index + 1): Calendar event - \(event.startDate?.description ?? "nil")")
                // Extract date from calendar event if not already found
                if extractedDate == nil {
                    extractedDate = event.startDate
                    if let date = extractedDate {
                        print("   ✅ Using as receipt date")
                    }
                }
                
            case .moneyAmount(let money):
                let amount = money.amount
                let code = money.currency.identifier
                
                // Check if this amount appears near promotional keywords
                let isPromotional = isPromotionalAmount(amount: amount, in: rawText)
                let status = isPromotional ? "⚠️ PROMOTIONAL (ignored)" : "✓ Valid"
                print("🔎 [ReceiptProcessor] Item \(index + 1): Money \(amount) \(code) - \(status)")
                
                visionAmounts.append((amount, code, isPromotional))
                
            default:
                // Skip other types silently to reduce log noise
                break
            }
        }
        
        // ============================================
        // STEP C: If TOTAL-line detection failed, try Vision amounts
        // ============================================
        if extractedAmount == nil {
            print("🔄 [ReceiptProcessor] Using Vision API amounts as fallback...")
            
            // Filter out promotional amounts and get the largest valid one
            let validAmounts = visionAmounts.filter { !$0.isPromotional }
            
            if let best = validAmounts.max(by: { $0.amount < $1.amount }) {
                extractedAmount = best.amount
                extractedCurrency = best.currency
                print("✅ [ReceiptProcessor] Using Vision amount: \(best.amount) \(best.currency)")
            } else if let anyAmount = visionAmounts.first {
                // Last resort: use any amount even if promotional
                print("⚠️ [ReceiptProcessor] Only promotional amounts found, using largest anyway...")
                if let largest = visionAmounts.max(by: { $0.amount < $1.amount }) {
                    // But cap it at a reasonable receipt amount (e.g., $10000)
                    if largest.amount <= 10000 {
                        extractedAmount = largest.amount
                        extractedCurrency = largest.currency
                    }
                }
            }
        }
        
        // ============================================
        // STEP D: Fallback date extraction if Vision didn't find any
        // ============================================
        if extractedDate == nil {
            print("🔄 [ReceiptProcessor] No date from Vision API, trying regex extraction...")
            extractedDate = extractDateFromText(rawText)
            if let date = extractedDate {
                print("✅ [ReceiptProcessor] Extracted date via regex: \(date)")
            } else {
                print("❌ [ReceiptProcessor] Date extraction failed")
            }
        }
        
        // Final summary
        print("� [ReceiptProcessor] -------- FINAL EXTRACTION --------")
        print("   Merchant: \(merchantName ?? "(none)")")
        print("   Amount: \(extractedAmount?.description ?? "(none)") \(extractedCurrency ?? "")")
        print("   Date: \(extractedDate?.description ?? "(none)")")
        
        return ReceiptMetadata(
            merchantName: merchantName,
            date: extractedDate,
            totalAmount: extractedAmount,
            currencyCode: extractedCurrency ?? detectCurrencyFromText(rawText),
            rawText: rawText
        )
    }
    
    // MARK: - Smart Merchant Name Extraction
    private func extractMerchantName(from lines: [String], rawText: String) -> String? {
        // Known merchant keywords to help identify business names
        let merchantKeywords = [
            "restaurant", "cafe", "coffee", "store", "shop", "mart", "market",
            "supermarket", "grocery", "pharmacy", "hotel", "mall", "mcdonald",
            "starbucks", "kfc", "pizza", "burger", "sdn bhd", "pvt ltd", "inc",
            "corp", "ltd", "llc", "co.", "enterprise", "trading", "services"
        ]
        
        // Patterns that indicate a line is NOT a merchant name
        let skipPatterns = [
            "^[A-Z]?\\d+[\\.]?$",             // Just numbers like "Q0583." or "190"
            "^\\d+$",                          // Pure numbers
            "^[#]?\\d+[-]?\\d*$",              // Receipt numbers like "#12345"
            "^\\d{1,2}[/\\-]\\d{1,2}[/\\-]\\d{2,4}$", // Dates
            "^\\d{1,2}:\\d{2}",                // Times
            "^tel",                            // Phone labels
            "^phone",
            "^fax",
            "^gst",                            // Tax IDs
            "^inv",                            // Invoice
            "^order",
            "^receipt",
            "^tax",
            "^total",
            "^subtotal",
            "^cash",
            "^change",
            "^qty",
            "^item"
        ]
        
        // First pass: Look for lines with known merchant keywords
        for line in lines.prefix(15) { // Check first 15 lines
            let lowerLine = line.lowercased()
            for keyword in merchantKeywords {
                if lowerLine.contains(keyword) && line.count >= 5 {
                    print("🏪 [ReceiptProcessor] Found merchant via keyword '\(keyword)': \"\(line)\"")
                    return cleanMerchantName(line)
                }
            }
        }
        
        // Second pass: Find first "real" line that looks like a business name
        for line in lines.prefix(10) {
            // Skip very short lines
            if line.count < 4 { continue }
            
            // Skip lines matching skip patterns
            var shouldSkip = false
            for pattern in skipPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                    let range = NSRange(line.startIndex..., in: line)
                    if regex.firstMatch(in: line, options: [], range: range) != nil {
                        shouldSkip = true
                        break
                    }
                }
            }
            if shouldSkip { continue }
            
            // Skip lines that are mostly numbers
            let letterCount = line.filter { $0.isLetter }.count
            let digitCount = line.filter { $0.isNumber }.count
            if digitCount > letterCount { continue }
            
            // Skip lines with phone number patterns
            if line.contains("-") && digitCount > 6 { continue }
            
            // This looks like a valid merchant name
            print("🏪 [ReceiptProcessor] Found merchant via heuristics: \"\(line)\"")
            return cleanMerchantName(line)
        }
        
        return nil
    }
    
    private func cleanMerchantName(_ name: String) -> String {
        var cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove common suffixes in parentheses like "(65351-M)"
        if let range = cleaned.range(of: "\\s*\\([^)]*\\)\\s*$", options: .regularExpression) {
            cleaned = String(cleaned[..<range.lowerBound])
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Fallback Date Extraction (Regex)
    private func extractDateFromText(_ text: String) -> Date? {
        // Common date patterns found on receipts
        let datePatterns = [
            // DD/MM/YYYY or DD-MM-YYYY
            "\\b(\\d{1,2})[/\\-](\\d{1,2})[/\\-](\\d{4})\\b",
            // YYYY/MM/DD or YYYY-MM-DD
            "\\b(\\d{4})[/\\-](\\d{1,2})[/\\-](\\d{1,2})\\b",
            // Month DD, YYYY (e.g., "January 15, 2025")
            "\\b(Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:t(?:ember)?)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\\s+(\\d{1,2}),?\\s+(\\d{4})\\b",
            // DD Month YYYY (e.g., "15 January 2025")
            "\\b(\\d{1,2})\\s+(Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:t(?:ember)?)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\\s+(\\d{4})\\b"
        ]
        
        let dateFormatter = DateFormatter()
        
        for pattern in datePatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let range = NSRange(text.startIndex..., in: text)
            
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                let matchedString = String(text[Range(match.range, in: text)!])
                print("🔄 [ReceiptProcessor] Found potential date string: \"\(matchedString)\"")
                
                // Try various date formats
                let formats = [
                    "dd/MM/yyyy", "dd-MM-yyyy",
                    "yyyy/MM/dd", "yyyy-MM-dd",
                    "MMMM dd, yyyy", "MMM dd, yyyy",
                    "dd MMMM yyyy", "dd MMM yyyy",
                    "MM/dd/yyyy", "MM-dd-yyyy"
                ]
                
                for format in formats {
                    dateFormatter.dateFormat = format
                    if let date = dateFormatter.date(from: matchedString) {
                        return date
                    }
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Smart Total Amount Extraction
    private func extractTotalFromReceipt(_ text: String) -> (amount: Decimal?, currency: String?) {
        let lines = text.components(separatedBy: .newlines)
        
        // Currency symbols and their codes - ORDER MATTERS (most specific first)
        let currencyMap: [(pattern: String, code: String)] = [
            ("rm\\s*", "MYR"),       // Malaysian Ringgit (RM)
            ("₹\\s*", "INR"),        // Indian Rupee
            ("rs\\.?\\s*", "INR"),   // Indian Rupee (Rs.)
            ("inr\\s*", "INR"),      // Indian Rupee
            ("zar\\s*", "ZAR"),      // South African Rand
            ("r\\s+(?=\\d)", "ZAR"), // South African Rand (R followed by space and digit)
            ("\\$\\s*", "USD"),      // US Dollar
            ("usd\\s*", "USD"),      // US Dollar
            ("€\\s*", "EUR"),        // Euro
            ("eur\\s*", "EUR"),      // Euro
            ("£\\s*", "GBP"),        // British Pound
            ("gbp\\s*", "GBP"),      // British Pound
            ("¥\\s*", "JPY"),        // Japanese Yen
            ("sgd\\s*", "SGD"),      // Singapore Dollar
            ("s\\$\\s*", "SGD"),     // Singapore Dollar (S$)
        ]
        
        // Keywords that indicate a TOTAL line (the amount can appear anywhere on the line)
        let totalKeywords = [
            "grand total",
            "total amount",
            "total due",
            "amount due",
            "amount payable",
            "balance due",
            "net total",
            "net amount", 
            "total",           // Most common - check last as it's most generic
            "tendered",        // Sometimes indicates the paid amount
            "subtotal",        // Subtotal before tax
            "bayar",           // Malay for pay
            "jumlah",          // Malay for total
        ]
        
        var bestAmount: Decimal?
        var bestCurrency: String?
        var foundKeyword: String?
        
        // Strategy: For each line, check if it contains a TOTAL keyword
        // If so, extract any monetary amount from that line (regardless of position)
        for line in lines {
            let lowerLine = line.lowercased().trimmingCharacters(in: .whitespaces)
            
            // Skip very short lines
            if lowerLine.count < 5 { continue }
            
            for keyword in totalKeywords {
                if lowerLine.contains(keyword) {
                    // Found a line with a total keyword - extract amount from this line
                    if let result = extractAmountFromLine(line, currencyMap: currencyMap) {
                        // For "subtotal", only use if we haven't found a better total yet
                        if keyword == "subtotal" && bestAmount != nil {
                            continue
                        }
                        
                        print("💰 [ReceiptProcessor] Found '\(keyword)' line: \"\(line.prefix(50))...\" -> \(result.amount) \(result.currency)")
                        
                        // Prefer "grand total" > "total" > "subtotal"
                        // If we already found a "total", don't replace with "subtotal"
                        if foundKeyword == "total" && keyword == "subtotal" {
                            continue
                        }
                        
                        bestAmount = result.amount
                        bestCurrency = result.currency
                        foundKeyword = keyword
                        
                        // If we found "grand total" or "total amount", that's definitely the one
                        if keyword == "grand total" || keyword == "total amount" {
                            return (bestAmount, bestCurrency)
                        }
                    }
                }
            }
        }
        
        // If we found something via TOTAL keywords, return it
        if let amount = bestAmount {
            return (amount, bestCurrency)
        }
        
        // Fallback: Look for the largest monetary amount in the document
        print("🔄 [ReceiptProcessor] No TOTAL keyword found, looking for largest amount...")
        var allAmounts: [(amount: Decimal, currency: String, line: String)] = []
        
        for line in lines {
            if let result = extractAmountFromLine(line, currencyMap: currencyMap) {
                // Skip very small amounts (likely cents/paise) and very large (likely item codes)
                if result.amount >= 1 && result.amount < 100000 {
                    allAmounts.append((result.amount, result.currency, line))
                }
            }
        }
        
        // Sort by amount descending and take the largest
        allAmounts.sort { $0.amount > $1.amount }
        
        if let largest = allAmounts.first {
            print("💰 [ReceiptProcessor] Using largest amount: \(largest.amount) \(largest.currency) from \"\(largest.line.prefix(40))...\"")
            return (largest.amount, largest.currency)
        }
        
        return (nil, nil)
    }
    
    private func extractAmountFromLine(_ line: String, currencyMap: [(pattern: String, code: String)]) -> (amount: Decimal, currency: String)? {
        // Pattern to match monetary amounts: optional currency symbol + number
        // Handle formats like: RM 45.90, $123.45, 123.45, Rs. 500.00
        
        var detectedCurrency = "USD" // Default
        
        // Check for currency indicators
        let lowerLine = line.lowercased()
        for (pattern, code) in currencyMap {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(lowerLine.startIndex..., in: lowerLine)
                if regex.firstMatch(in: lowerLine, options: [], range: range) != nil {
                    detectedCurrency = code
                    break
                }
            }
        }
        
        // Extract numbers that look like monetary amounts (with decimal point and 2 digits)
        // Match: 123.45 or 1,234.56 or 123.4 or just 123
        let amountPattern = "([\\d,]+\\.\\d{1,2})\\b"
        
        guard let regex = try? NSRegularExpression(pattern: amountPattern, options: []) else { return nil }
        let range = NSRange(line.startIndex..., in: line)
        
        var largestInLine: Decimal?
        
        let matches = regex.matches(in: line, options: [], range: range)
        for match in matches {
            if let amountRange = Range(match.range(at: 1), in: line) {
                let amountString = String(line[amountRange]).replacingOccurrences(of: ",", with: "")
                if let amount = Decimal(string: amountString) {
                    if let current = largestInLine {
                        if amount > current { largestInLine = amount }
                    } else {
                        largestInLine = amount
                    }
                }
            }
        }
        
        if let amount = largestInLine {
            return (amount, detectedCurrency)
        }
        
        return nil
    }
    
    // MARK: - Promotional Amount Detection
    /// Checks if a money amount appears near promotional keywords (sweepstakes, prizes, etc.)
    private func isPromotionalAmount(amount: Decimal, in text: String) -> Bool {
        // Format the amount to search for it in text
        let amountStr = "\(amount)"
        let amountInt = Int(truncating: amount as NSDecimalNumber)
        
        // Promotional keywords that indicate an amount is NOT a real transaction
        let promotionalKeywords = [
            "win", "won", "winner", "prize", "prizes",
            "chance", "chances", "lucky", "lottery", "sweepstakes",
            "giveaway", "give away", "free", "bonus",
            "reward", "rewards", "earn", "earning",
            "cashback", "cash back", "save up to",
            "enter to", "could win", "you could",
            "drawing", "raffle", "contest"
        ]
        
        let lowerText = text.lowercased()
        
        // Check if any promotional keyword appears near this amount
        // We look for the keyword within ~50 characters of the amount
        for keyword in promotionalKeywords {
            if lowerText.contains(keyword) {
                // Check if the amount appears near this keyword
                if let keywordRange = lowerText.range(of: keyword) {
                    let keywordIndex = lowerText.distance(from: lowerText.startIndex, to: keywordRange.lowerBound)
                    
                    // Look for the amount value in text
                    let searchPatterns = [
                        "\(amountInt)",           // "1000"
                        "$\(amountInt)",          // "$1000"  
                        "$ \(amountInt)",         // "$ 1000"
                        "\(amountInt).00",        // "1000.00"
                        "$\(amountInt).00",       // "$1000.00"
                    ]
                    
                    for pattern in searchPatterns {
                        if let amountRange = lowerText.range(of: pattern.lowercased()) {
                            let amountIndex = lowerText.distance(from: lowerText.startIndex, to: amountRange.lowerBound)
                            let distance = abs(keywordIndex - amountIndex)
                            
                            // If amount is within 80 characters of promotional keyword, it's likely promotional
                            if distance < 80 {
                                print("   🎯 [ReceiptProcessor] Amount \(amount) flagged as promotional (near '\(keyword)')")
                                return true
                            }
                        }
                    }
                }
            }
        }
        
        // Also flag suspiciously round large amounts that are typical of promotions
        // e.g., $1000, $500, $100, $5000, $10000
        let roundPromotionalAmounts: [Decimal] = [100, 500, 1000, 2000, 5000, 10000, 25000, 50000, 100000]
        if roundPromotionalAmounts.contains(amount) {
            // Check if any promotional keyword exists in the entire text
            for keyword in promotionalKeywords {
                if lowerText.contains(keyword) {
                    print("   🎯 [ReceiptProcessor] Round amount \(amount) flagged as promotional (text contains '\(keyword)')")
                    return true
                }
            }
        }
        
        return false
    }
    
    // MARK: - Currency Detection
    private func detectCurrencyFromText(_ text: String) -> String {
        let lowerText = text.lowercased()
        
        // Check for currency indicators in priority order (most specific first)
        if lowerText.contains("rm ") || lowerText.contains("ringgit") || lowerText.contains("myr") {
            return "MYR"
        }
        if lowerText.contains("₹") || lowerText.contains("rs.") || lowerText.contains("rs ") || lowerText.contains("inr") {
            return "INR"
        }
        // South African Rand - check before USD since R is common
        if lowerText.contains("zar") || lowerText.contains("rand") {
            return "ZAR"
        }
        // Check for "R" followed by a number (South African pattern like "R 17.99")
        if let regex = try? NSRegularExpression(pattern: "\\br\\s+\\d", options: .caseInsensitive) {
            let range = NSRange(lowerText.startIndex..., in: lowerText)
            if regex.firstMatch(in: lowerText, options: [], range: range) != nil {
                return "ZAR"
            }
        }
        if lowerText.contains("$") || lowerText.contains("usd") {
            return "USD"
        }
        if lowerText.contains("€") || lowerText.contains("eur") {
            return "EUR"
        }
        if lowerText.contains("£") || lowerText.contains("gbp") {
            return "GBP"
        }
        if lowerText.contains("s$") || lowerText.contains("sgd") {
            return "SGD"
        }
        
        // Default to USD as a neutral fallback
        return "USD"
    }
}

// MARK: - Preview Helper
#if DEBUG
extension ReceiptMetadata {
    static let sample = ReceiptMetadata(
        merchantName: "Whole Foods Market",
        date: Date(),
        totalAmount: 127.45,
        currencyCode: "USD",
        rawText: "Sample receipt text"
    )
}
#endif
