##return all pairwise combinations of people in a given column
##Author: Kathryn Winglee

library(xlsx)

##base file names
defaultNoTimeLogName = "LATTE_NoDate_Log.txt" #default name of log file
strength.options = c("definite", "probable", "possible", "none", "custom")

##returns all combinations of names in list
##colname = name of column in original table (becomes label)
##list = list of names
##strength = strength to assign
##returns the data frame of pairs, the number of unique people in the list, and a list of duplicated people
allCombo <- function(colname, list, strength) {
  list = as.character(list)
  list = list[!is.na(list) & list!=""] #may have empty elements because some places will have fewer people
  
  if(any(duplicated(list))) {
    dup = unique(list[duplicated(list)])
    list = list[!duplicated(list)]
  } else {
    dup = NA
  }
  
  if(length(list) >= 2) {
    ##set up result
    nrow = length(list) * (length(list)-1) / 2
    res = data.frame(ID1 = rep(NA, nrow),
                     ID2 = rep(NA, nrow),
                     Strength = strength,
                     Label = colname)
    index = 1
    
    ##get pairwise combos
    for(i in 1:(length(list)-1)) {
      for(j in (i+1):length(list)) {
        res$ID1[index] = list[i]
        res$ID2[index] = list[j]
        index = index + 1
      }
    }
  } else {
    res = NA
  }
  
  return(list(res=res, n=length(list), dup=dup))
}

##removes whitespace to avoid issues of names not matching due to extra spaces around variables
removeWhitespace <- function(vec) {
  vec = gsub("^\\s+", "", vec)
  vec = gsub("\\s+$", "", vec)
  return(vec)
}

##generates the pairwise combinations for the data contained in fname
##fname = file containing the list of people to turn into pairs
##strength = strength to assign to the pair
##custom = if strength is "custom", custom is the table of strengths for each column in fname, otherwise is NA
##log = file to write messages to
latteNoTime <- function(fname, strength="", custom=NA, log=defaultNoTimeLogName, progress = NA) {
  cat("LATTE analysis without date data\r\n", file = log)
  ##read fname without header to keep special characters
  if(endsWith(fname, ".xlsx")) {
    df = read.xlsx(fname, sheetIndex = 1, header = F)
  } else if(endsWith(fname, ".csv")) {
    df = read.table(fname, header = F, sep = ",")
  } else if(endsWith(fname, ".txt")) {
    df = read.table(fname, header = F, sep = "\t")
  } else {
    cat("Table of grouped people must be an Excel (.xlsx extension) or CSV (.csv extension) file.\r\n", file = log, append = T)
    stop("Table of grouped people must be an Excel (.xlsx extension) or CSV (.csv extension) file.")
  }
  
  if(all(class(progress)!="logical")) {
    progress$set(value = 1, detail = "running data checks")
  }
  
  ##check table
  ##remove extra empty columns
  c = 1
  while(c <= ncol(df)) {
    if(all(is.na(df[,c]))) {
      df = as.data.frame(df[,-c]) #in case get to 1 column
    } else {
      c = c + 1
    }
  }
  # cat(paste(ncol(df), "columns included in analysis.\r\n"), file = log, append = T)
  cat(paste(ncol(df), "columns found for analysis.\r\n"), file = log, append = T)
  if(ncol(df) < 1) {
    cat("Table of grouped people must have at least one non-empty column.\r\n", file = log, append = T)
    stop("Table of grouped people must have at least one non-empty column.")
  }
  if(nrow(df) < 3) {
    cat(paste0("Table of grouped people must have at least 3 rows (column name and two people), but this table only has ", 
              nrow(df), ifelse(nrow(df)==1, " row", " rows"), ".\r\n"), file = log, append = T)
    stop("Table of grouped people in locations must have at least 3 rows.")
  }
  ##check column names
  for(c in 1:ncol(df)) {
    df[,c] = removeWhitespace(as.character(df[,c]))
  }
  vars = as.character(df[1,])
  if(any(is.na(vars) | vars == "")) {
    miss = which(is.na(vars) | vars == "")
    cat(paste0("Column name is missing in the table of grouped people for the following columns: ", paste(miss, collapse = ", "),
               ". The name assigned will be ", paste(paste0("Column", miss), collapse = ", "), 
               ifelse(length(miss)==1, ".", " respectively."), "\r\n"), file = log, append = T)
    df[1,miss] = paste0("Column", miss)
    vars = as.character(df[1,])
  }
  ##look for duplicate column names
  cn = character()
  for(c in 1:ncol(df)) {
    cn = c(cn, as.character(df[[1,c]]))
  }
  if(any(duplicated(cn))) {
    dup = unique(cn[duplicated(cn)])
    cat(paste0(paste(dup, collapse = ","), " is in the table of grouped people twice. Column names must be unique.\r\n"), file = log, append = T) #stop here
    stop("Column names in the table of grouped people must be unique.")
  }
  ##check strength
  strength = tolower(strength)
  if(!strength %in% strength.options) {
    cat(paste0("Provided strength is ", strength, 
               # ", which is not one of the recommended options. Recommended strengths are definite, probable, possible, none (strength left blank), or custom.\r\n"),
               ", which is not one of the strength options. Strength options are definite, probable, possible, none (strength left blank), or custom.\r\n"),
        file = log, append = T)
    stop("Invalid strength: ", strength)
  }
  cat(paste0("Using strength: ", strength, ".\r\n"), file = log, append = T)
  if(strength == "none") {
    strength = ""
  } 
  
  ##set up custom
  if(strength == "custom" & all(is.na(custom))) {
    cat("Custom strength was selected but no custom strengths were provided. If user wants to use custom strengths, they must provide a table of custom strengths.\r\n",
        file = log, append = T)
    stop("Custom strength was selected but no table of custom strengths was provided.")
  }
  if(strength != "custom" & !all(is.na(custom))) {
    cat("Table of custom strengths was provided but will be ignored as another overall strength was provided.\r\n",
        file = log, append = T)
    custom = NA
  }
  if(!all(is.na(custom))) {
    # ##variable column
    # col = grepl("variable", names(custom), ignore.case = T)
    # if(sum(col) == 1) {
    #   names(custom)[col] = "variable"
    # } else if(sum(tolower(names(custom))=="variable")==1) {
    #   names(custom) = tolower(names(custom))
    # } else if(sum(col) > 1) {
    #   cat(paste("More than one column for custom strength variable name in custom strength table, so custom strength cannot be used:", 
    #             paste(names(custom)[col], collapse = ", "),
    #       "\r\nPlease label one column in custom strength table \"variable\"."),
    #       file = log, append = T)
    #   stop(paste("More than one column for custom strength variable name in custom strength table:", 
    #                 paste(names(custom)[col], collapse = ", ")))
    # } else if(sum(col) < 1) {
    #   cat("No custom strength variable column in risk factor table, so custom strength cannot be used.\r\nPlease add a column named variable to the custom strength table.\r\n", 
    #       file = log, append = T)
    #   stop("No custom strength variable column in risk factor table, so custom strength cannot be used.\r\n")
    # }
    # ##strength
    # col = grepl("strength", names(custom), ignore.case = T)
    
    ###check column names
    names(custom) = tolower(names(custom))
    if(!"variable" %in% names(custom)) {
        cat("No variable column in table of custom strengths, so custom strength cannot be used.\r\nPlease add a column named \"variable\" to the table of custom strengths.\r\n",
            file = log, append = T)
        stop("No variable column in table of custom strengths, so custom strength cannot be used.\r\n")
    }
    if(!"strength" %in% names(custom)) {
      cat("No strength column in table of custom strengths, so custom strength cannot be used.\r\nPlease add a column named \"strength\" to the table of custom strengths.\r\n",
          file = log, append = T)
      stop("No strength column in table of custom strengths, so custom strength cannot be used.\r\n")
    }
    
    custom = custom[,c("variable", "strength")]
    ##remove whitespace
    custom$variable = removeWhitespace(as.character(custom$variable))
    custom$strength = removeWhitespace(as.character(custom$strength))
    
    ###check strengths
    custom$strength = tolower(custom$strength)
    tmp = which(is.na(custom$strength) | custom$strength=="")
    if(length(tmp)) {
      cat(paste0("The following row(s) in the table of custom strengths had a missing strength value: ", paste(tmp, collapse = ", "),
                 ". The corresponding pairs of persons will be missing a strength value.\r\n"), file = log, append = T)
    }
    if(!all(custom$strength %in% c(strength.options, NA, ""))) {
      miss = custom$strength[!custom$strength %in% c(strength.options, NA, "")]
      cat(paste0(paste(miss, collapse = ", "), ifelse(length(miss)==1, " is one of the", " are"),
                 " strengths listed in the table of custom strengths but ", ifelse(length(miss)==1, "is", "are"), 
                 # " not one of the recommended options. Recommended strengths are definite, probable, possible, or none.\r\n"),
                 " not one of the strength options. Strength options are definite, probable, possible, or none (strength left blank).\r\n"),
          file = log, append = T)
      stop("Invalid custom strength: ", paste(miss, collapse = ", "))
    }
    
    ###remove empty variables
    tmp = which(is.na(custom$variable) | custom$variable=="")
    if(length(tmp)) {
      cat(paste0("The following rows in the table of custom strengths are missing a variable: ", paste(tmp, collapse = ", "),
                 ". These rows will be removed.\r\n"), file = log, append = T)
      custom = custom[-tmp,]
    }
    
    ###check have all variables
    if(!all(vars %in% custom$variable)) {
      miss = vars[!vars %in% custom$variable]
      cat(paste0("The following variables are in the table of grouped people but not listed in the table of custom strengths: ", 
                 paste(miss, collapse = ", "),
                 ". The pairs corresponding to ",
                 ifelse(length(miss)==1, "this variable", "these variables"), 
                 " will be missing a strength value (strength left blank).\r\n"), file = log, append = T)
      custom = rbind(custom,
                     data.frame(variable = miss,
                                strength = NA))
    }
    
    ###check for extra variables
    if(!all(custom$variable %in% vars)) {
      miss = custom$variable[!custom$variable %in% vars]
      cat(paste0("The following variables are in the table of custom strengths but not listed in the table of grouped people: ", 
                 paste(miss, collapse = ", "), ". ",
                 ifelse(length(miss)==1, "This variable", "These variables"), 
                 " will be ignored.\r\n"), file = log, append = T)
      custom = custom[custom$variable %in% vars,]
    }
    custom$variable = as.character(custom$variable)
    custom$strength = as.character(custom$strength)
  }
  
  if(all(class(progress)!="logical")) {
    progress$set(value = 2, detail = "making links")
  }
  
  ##run the pairs
  res = NA
  numPeople = data.frame(name=vector(), n=vector()) #table of number of unique persons associated with each location
  for(c in 1:ncol(df)) {
    colname = df[1,c]
    list = df[-1,c]
    if(all(is.na(custom))) {
      s = strength
    } else {
      s = custom$strength[custom$variable==colname]
    }
    r = allCombo(colname = colname, list = list, strength = s)
    numPeople = rbind(numPeople,
                      data.frame(name=colname, n=r$n))
    if(!all(is.na(r$dup))) { #there were duplicated people; indicate in log
      cat(paste0("The following people were listed multiple times in ", colname, ": ",
                 paste(r$dup, collapse = ", "),
                 ". The duplications were removed from the list so that they only appear once in the pairs.\r\n"),
          file = log, append = T)
    }
    r = r$res
    if(all(is.na(r))) { #less than two people in this column
      cat(paste0(colname, " was included in the input but had fewer than two people so no pairs were made.\r\n"),
          file = log, append = T)
    } else {
      if(all(is.na(res))) {
        res = r
      } else {
        res = rbind(res, r)
      }
    }
    if(all(class(progress)!="logical")) {
      progress$set(value = 2 + 2*(ncol(df)/c)) #add to 4 but update on every iteration
    }
  }
  ##print number of unique people in each location
  cat("Number of unique people in each column:\r\nColumn name\t\tNumber\r\n", file = log, append = T)
  for(n in 1:nrow(numPeople)) {
    cat(paste0(numPeople$name[n], "\t\t", numPeople$n[n], "\r\n"), file = log, append = T)
  }
  return(list(pairs = res,
              input = df,
              custom = custom))
}

##run the LATTE algorithm and then produce Excel files of results
##outPrefix = prefix for output files
##fname = file containing the list of people to turn into pairs
##strength = strength to assign to the pair
##custom = if strength is "custom", custom is the table of strengths for each column in fname, otherwise is NA
latteNoTimeWithOutputs <- function(outPrefix, fname, strength, custom=NA, progress = NA) {
  log = paste(outPrefix, defaultNoTimeLogName, sep="")
  result = latteNoTime(fname = fname, strength = strength, custom = custom, log = log, progress = progress)
  
  ##set up files
  pairName = paste0(outPrefix, "LATTE_NoDate_Pairs.xlsx")
  inputName = paste0(outPrefix, "LATTE_NoDate_Input_People.xlsx")
  customName = paste0(outPrefix, "LATTE_NoDate_Input_Strengths.xlsx")
  outputExcelFiles = c(pairName, inputName, customName)
  if(any(file.exists(outputExcelFiles))) {
    del = outputExcelFiles[file.exists(outputExcelFiles)]
    file.remove(del)
  }
  
  ##write pair file
  pair = result$pairs
  if(!all(is.na(pair))) {
    writeExcelTableNoTime(fileName = pairName, sheetName = "Pairs", df = pair)
  } else {
    outputExcelFiles = outputExcelFiles[outputExcelFiles!=pairName]
  }
  if(all(class(progress)!="logical")) {
    progress$set(value = 5, detail = "generating output tables")
  }
  
  ##write input file
  input = result$input
  colname = as.character(input[1,])
  input = input[-1,]
  if(class(input)!="data.frame") {
    input = data.frame(x=input)
  }
  names(input) = colname
  writeExcelTableNoTime(fileName = inputName, sheetName = "People", df = input, filter = F)
  if(all(class(progress)!="logical")) {
    progress$set(value = 6)
  }
  
  ##write custom file
  custom = result$custom
  if(!all(is.na(custom))) {
    names(custom) = c("Variable", "Strength")#in cleaning, was put in this order
    writeExcelTableNoTime(fileName = customName, sheetName = "Strengths", df = custom, filter = F)
  } else {
    outputExcelFiles = outputExcelFiles[outputExcelFiles!=customName]
  }
  if(all(class(progress)!="logical")) {
    progress$set(value = 7)
  }
  
  ##return
  result$outputFiles = c(log, outputExcelFiles)
  return(result)
}

##writes the data frame df to the Excel file or workbook and sheet
##differs from LATTE in that filter is optional, no save
##fileName = name of Excel file to write
##sheetName = name of sheet
##df = data to write
##if wrapHeader is true, set column widths to the longest length and wrap the header (rather than using auto, which will not wrap the header)
##if filter is true, add a filter to all columns
writeExcelTableNoTime<-function(fileName, sheetName="Sheet1", df, wrapHeader=F, filter=T) {
  workbook = createWorkbook()
  sheet = createSheet(workbook, sheetName = sheetName)
  rows = createRow(sheet, rowIndex = 1:(nrow(df)+1))
  cells = createCell(rows, colIndex = 1:ncol(df))
  
  ##header
  headstyle = CellStyle(workbook) + Fill(foregroundColor = rgb(red = 192, green = 192, blue = 192, maxColorValue = 255))
  if(wrapHeader) {
    headstyle = headstyle + Alignment(wrapText = T)
  }
  for(c in 1:ncol(df)) {
    setCellValue(cells[[1,c]], names(df)[c])
    setCellStyle(cells[[1,c]], headstyle)
  }
  ##write data
  for(r in 1:nrow(df)) {
    for(c in 1:ncol(df)) {
      if(!is.na(df[r,c])) {
        if(as.character(df[r,c])!="") {
          if(all(grepl("[0-9.]", strsplit(as.character(df[r,c]), "")[[1]]))) {
            setCellValue(cells[[r+1,c]], as.numeric(as.character(df[r,c])))
          } else {
            setCellValue(cells[[r+1,c]], df[r,c])
          }
        }
      }
    }
  }
  ##set column widths
  if(wrapHeader) {
    cwidth = (sapply(1:ncol(df), function(c){max(nchar(as.character(df[,c]), keepNA=F))})+5)#*256 #width is 1/256 of char
    minWidth = 11# 10*256 #minimum width for column
    cwidth[cwidth < minWidth] = minWidth
    for(c in 1:length(cwidth)) {
      setColumnWidth(sheet = sheet, colIndex = c, colWidth = cwidth[c])
    }
  } else {
    autoSizeColumn(sheet, 1:ncol(df))
  }
  ##add filter
  if(filter) {
    r1 = sheet$getRow(1L)
    lastcol = r1$getCell(as.integer(ncol(df)-1))
    addAutoFilter(sheet = sheet, cellRange =paste("A1:", lastcol$getReference(), sep=""))
  }
  saveWorkbook(workbook, fileName)
}

