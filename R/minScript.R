#'
#' The minScript
#'
#' @author Timo Wagner, \email{wagnertimo@gmx.de}
#'
#' This sscript file contains a minimal version with all necessary functions to crawl, preprocess, callculate the approximated 1min operating reserve calls and calculate the marginal workprices.
#' All printings in the console are omitted.
#'
#' @references @seealso scrapeData.R
#' @references @seealso preprocessData.R
#'
#' Some useful keyboard shortcuts for package authoring:
#'
#'  Build and Reload Package:  'Cmd + Shift + B'
#'  Check Package:             'Cmd + Shift + E'
#'  Test Package:              'Cmd + Shift + T'
#'

#' @title setLogging
#'
#' @description This function sets a global options variable called "logging" to TRUE OR FALSE. By default it is FALSE, so no logging is displayed.
#'
#' @param logger - A boolean variable. TRUE for printing out the logging outputs in the console.
#'
#'
#' @export
#'
setLogging <- function(logger) {
  options("logging" = logger)
  ifelse(logger == TRUE, print("Outputs/logs will be displayed!"), print("No console outputs/logs will be displayed!"))
}





# -----------------------------------------------------------------------------------------------------------------------------------------
# MAIN FUNCTION getReserveNeds


#' @title getReserveNeeds
#'
#' @description This function is the production method of @seealso getOperatingReserveNeeds in the @seealso scrapeData.R script. It is without console prints for faster computation and several steps are combined.
#' This main function retrieves the operating reserve needs from \url{https://www.transnetbw.de/de/strommarkt/systemdienstleistungen/regelenergie-bedarf-und-abruf}.
#' The resolution is 4sec. The function can take awhile since it has to download sever MBs of data. The oldest data that can be retrieved is July (07) 2010.
#' The method also preprocesses the data in a nice format.
#' Variables in the returned data.frame:  - MW (numeric). The signed power needs for every 4sec. Point as decimal delimiter
#'                                        - DateTime (POSIXct). DateTime object in Y-m-d h:m:s format. Be aware of daylight saving. 4sec time windows.
#'
#' CAUTION!!! ---> DO NOT EXPAND THE TIME PERIOD OVER SEVERAL YEARS --> ONLY ONE YEAR IS ALLOWED (--> see addTimezone function!)
#'
#' @param startDate sets the starting date. Format (german style): DD.MM.YYYY CAUTION!!! ---> DO NOT EXPAND THE TIME PERIOD OVER SEVERAL YEARS --> ONLY ONE YEAR IS ALLOWED
#' @param endDate sets the ending date. Format (german style): DD.MM.YYYY CAUTION!!! ---> DO NOT EXPAND THE TIME PERIOD OVER SEVERAL YEARS --> ONLY ONE YEAR IS ALLOWED
#'
#' @return data.frame variable containing the 4sec operating reserve needs.
#'
#' @examples
#' needs <- getReserveNeeds("30.12.2015", "02.01.2016")
#'
#' @export
#'
getReserveNeeds <- function(startDate, endDate) {
  library(logging)

  # Setup the logger and handlers
  basicConfig(level="DEBUG") # parameter level = x, with x = debug(10), info(20), warn(30), critical(40) // setLevel()
  nameLogFile <- paste("getReserveNeeds_", gsub(":", "", as.character(Sys.time())), ".txt", sep="")
  addHandler(writeToFile, file=nameLogFile, level='DEBUG')

  df <- preprocessOperatingReserveNeeds(getOperatingReserveNeeds(startDate, endDate))

  return(df)

}


# -----------------------------------------------------------------------------------------------------------------------------------------
# MAIN FUNCTION getReserveCalls


#' @title getReserveCalls
#'
#' @description This function is the production method of @seealso getOperatingReserveCalls in the @seealso scrapeData.R script. It is without console prints for faster computation and several steps are combined.
#' This main function retrieves the 15min operating reserve calls (not qualified) from \url{https://www.regelleistung.net/ext/data/}.
#' The oldest data that can be retrieved is 2011-06-27.
#' The method also preprocesses the data in a nice format.
#' Variables in the returned data.frame:  - neg_MW (numeric). The signed power calls within the 15min time window. Point as decimal delimiter
#'                                        - pos_MW (numeric). The signed power calls within the 15min time window. Point as decimal delimiter
#'                                        - DateTime (POSIXct). DateTime object in Y-m-d h:m:s format. Be aware of daylight saving. 15min time windows.
#'
#' CAUTION!!! ---> DO NOT EXPAND THE TIME PERIOD OVER SEVERAL YEARS --> ONLY ONE YEAR IS ALLOWED (--> see addTimezone function!)
#'
#'
#' @param startDate - sets the starting date. Format (german style): DD.MM.YYYY CAUTION!!! ---> DO NOT EXPAND THE TIME PERIOD OVER SEVERAL YEARS --> ONLY ONE YEAR IS ALLOWED
#' @param endDate - sets the ending date. Format (german style): DD.MM.YYYY CAUTION!!! ---> DO NOT EXPAND THE TIME PERIOD OVER SEVERAL YEARS --> ONLY ONE YEAR IS ALLOWED
#' @param uenb - 50Hz (4), TenneT (2), Amprion (3), TransnetBW (1), Netzregelverbund (6), IGCC (11)
#' @param rl - SRL, MRL, RZ_SALDO, REBAP, ZUSATZMASSNAHMEN, NOTHILFE
#'
#' @return data.frame variable containing the operating reserve call table
#'
#' @examples
#' # Get the secondary calls for one week of the Netzregelverbund
#' calls <- getReserveCalls('07.03.2017', '14.03.2017', '6', 'SRL')
#'
#' @export
#'
getReserveCalls <- function(startDate, endDate, uenb, rl) {
  library(logging)

  # Setup the logger and handlers
  basicConfig(level="DEBUG") # parameter level = x, with x = debug(10), info(20), warn(30), critical(40) // setLevel()
  nameLogFile <- paste("getReserveCalls_", gsub(":", "", as.character(Sys.time())), ".txt", sep="")
  addHandler(writeToFile, file=nameLogFile, level='DEBUG')

  df <- preProcessOperatingReserveCalls(getOperatingReserveCalls(startDate, endDate, uenb, rl))

  return(df)

}



# -----------------------------------------------------------------------------------------------------------------------------------------
# MAIN FUNCTION getReserveAuctions


#' @title getReserveAuctions
#'
#' @description This function is the production method of @seealso getOperatingReserveAuctions in the @seealso scrapeData.R script. It is without console prints for faster computation and several steps are combined.
#' This main function retrieves the operating reserve auction results from \url{https://www.regelleistung.net/ext/tender/}.
#' The data contains all auctions from a given start date till an end date. Be aware of the weekly data and take care of the latest week.
#' CAUTION: IF YOUR START WEEK CONTAINS NO AUCTION RESULTS, THIS COULD LEAD TO AN ERROR! --> BUT NORMALLY THERE SHOULD BE NO START WEEK WITH ZERO ENTRIES!
#' Variables in the returned data.frame:  - power_price (numeric). The signed power price of the bid. Point as decimal delimiter.
#'                                        - work_price (numeric). The signed work price of the bid. Point as decimal delimiter. There are also negative prices.
#'                                        - offered_power_MW (numeric). The offered power in MW. Point as decimal delimiter. 5 as the minimal bid. This will be changed someday to smaller increments.
#'                                        - Tarif (char). Contains the value of either "HT", the main tarif or "NT", for the remaining time periods.
#'                                        - Direction (char). Contains the value of either "POS", for positive operating reserve power, or "NEG" for negative power.
#'                                        - date_from (Date). Date object in Y-m-d format. The two date variables build the one week auction time period. This will be changed someday.
#'                                        - date_to (Date). Date object in Y-m-d format. The two date variables build the one week auction time period. This will be changed someday.
#'
#' @param startDate the start date to retrieve all auctions. Format (german style): DD.MM.YYYY (e.g.'07.03.2017')
#' @param endDate the end date to retrieve all auctions. Format (german style): DD.MM.YYYY (e.g.'07.03.2017')
#' @param rl PRL (1), SRL (2), MRL (3), sofort abschaltbare Lasten (4), schnell abschaltbare Lasten (5), Primärregelleistung NL (6)
#'
#' @return data.frame with the results of the auctions held from start date till end date
#'
#' @examples
#' # Get the auction results of the secondary operating reserve power for one week of that specific day
#' auctions <- getReserveAuctions('07.03.2017','07.03.2017', '2')
#'
#' @export
#'
getReserveAuctions <- function(startDate, endDate, rl) {
  library(logging)

  # Setup the logger and handlers
  basicConfig(level="DEBUG") # parameter level = x, with x = debug(10), info(20), warn(30), critical(40) // setLevel()
  nameLogFile <- paste("getReserveAuctions_", gsub(":", "", as.character(Sys.time())), ".txt", sep="")
  addHandler(writeToFile, file=nameLogFile, level='DEBUG')

  df <- preprocessOperatingReserveAuctions(getOperatingReserveAuctions(getAuctionDates(startDate, endDate)$start, getAuctionDates(startDate, endDate)$end, rl), rl)

  return(df)

}


# This helper function is needed in the getReserveAuctions method to format the input dates (start and end)
# It takes care of the weekly auctions such that the input dates are mapped to monday and sunday dates.
# E.g. 01.01.2016 to 31.12.2016 is mapped to 28.12.2015 to 01.01.2017 because those are the right dates starting the week from monday till sunday
# Therefore the function returns a list. $start is the formatted start date and $end the formatted end date
#
getAuctionDates <- function(startDate, endDate){
  library(lubridate)
  library(zoo)

  s <- as.Date(startDate, "%d.%m.%Y")
  e <- as.Date(endDate, "%d.%m.%Y")

  # 1 = sunday , 2 = monday ... 7 saturday
  # start should be monday --> if not shift date BACKWARDS to monday
  sdiffback <- wday(s) - 2 # if sunday (1) --> so diff is neg. (<0) --> shift back 6

  # end should be sundady ---> if not shift date FORWARDS to sunday
  ediffforward <- 7 - (wday(e) - 1) # if diff is 7 than it is the correct sunday

  start <- if(sdiffback >= 0) s - sdiffback else s - 6
  end <- if(ediffforward == 7) e else e + ediffforward

  if(getOption("logging")) loginfo(paste("getAuctionDates - New auction dates, start: ", start, " | end: ", end))

  rlist <- list(start = as.character(format(start, "%d.%m.%Y")), end = as.character(format(end, "%d.%m.%Y")))
  return(rlist)

}



