# MIT License
# 
# Copyright (c) 2018 Raphael Reitzig
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

library(dplyr)

#' The predefined, fixed column names in both the source CSV and 
#' the result of \code{loadSpiritData}. 
fixedColumns <- c("Team1", "Team2", "Evaluator", "Evaluated")

#' Loads spirit data from a CSV file.
#' 
#' We expect the file to contain one column for each of the names 
#' in \code{fixedColumns}. All other columns are interpreted as 
#' individual scores, e.g. Attitude and Communication. That is, they
#' should contain integer values between 0 and 4 (inclusive).
#' 
#' @param file Name of the file to read from.
#' @return A data frame of the individual spirit assessments.
loadSpiritData <- function(file) {
  raw <- read.csv(file = file)
  
  names <- scoreNames(raw)
  
  # Check that scores are 0 <= _ <= 4
  if ( !all(0 <= raw[,names], raw[,names] <= 4) ) {
    warning("Invalid score values! Must be 0 <= x <= 4.")
    return()
  }
  
  # Check that evaluator/evaluated match playing teams
  badRows <- filter(raw, (as.character(Evaluator) != as.character(Team1) & as.character(Evaluator) != as.character(Team2)) | (as.character(Evaluated) != as.character(Team1) & as.character(Evaluated) != as.character(Team2)))
  if ( nrow(badRows) > 0 ) {
    warning("Some rows have bad team names!")
    show(badRows)
    return()
  }
  
  # Obtain set of teams
  teams <- as.factor(unique(c(levels(raw$Team1),levels(raw$Team2))))
  
  # Normalize columns with team references to use a common factor
  raw$Team1 <- factor(raw$Team1, levels = teams)
  raw$Team2 <- factor(raw$Team2, levels = teams)
  raw$Evaluator <- factor(raw$Evaluator, levels = teams)
  raw$Evaluated <- factor(raw$Evaluated, levels = teams)
  
  # Check that evaluations are symmetric
  for ( t1 in teams ) {
    for ( t2 in teams ) {
      # Yea, we check every pair twice... doesn't matter much for a few teams.
      # Should code this nicer at some point.
      count1for2 <- nrow(filter(raw, Evaluator == t1 & Evaluated == t2))
      count2for1 <- nrow(filter(raw, Evaluator == t2 & Evaluated == t1)) 
      if ( count1for2 != count2for1 ) {
        warning(paste("Team ", t1, " scored ", t2, " ", count1for2, " times, but ", t2, " scored ", t1, " ", count2for1, " times!"))
      }
    }
  }
  
  return(raw)
}

#' Extracts the names of the score categories from the given data set.
#' 
#' @param spiritData Data as read by \code{loadSpiritData}.
#' @return All column names besides those from \code{fixedColumns}.
scoreNames <- function(spiritData) {
  return(setdiff(colnames(spiritData), fixedColumns))
}

#' Extracts the team names from the given spirit data.
#' 
#' @param spiritData Data as read by \code{loadSpiritData}.
#' @return The vector of teams that appear in \code{spiritData}.
teams <- function(spiritData) {
  return(levels(spiritData$Team1))
}

#' Aggregates the assessments from resp. for a certain team.
#' 
#' @param spiritData Data as read by \code{loadSpiritData}.
#' @param from The team assessing the other(s). If unset, lists all teams.
#' @param to The team being assessed. If unset, list all teams.
#' @param average If \code{TRUE}, the matching assessments are averaged.
#'                If \code{FALSE}, all matching assessments are returned.
#' @return A data frame with the (aggregate) score(s) as specified.
score <- function(spiritData, from = NA, to = NA, average = TRUE) {
  selected <- spiritData %>%
    filter((is.na(from) & Evaluator != to) | Evaluator == from) %>%
    filter((is.na(to) & Evaluated != from) | Evaluated == to) #%>%
  
  if ( average ) {
    selected <- summarize(selected, 
                          From = from, 
                          To = to, 
                          Rules = mean(Rules), 
                          Contact = mean(Contact), 
                          Fair = mean(Fair), 
                          Attitude = mean(Attitude), 
                          Communication = mean(Communication))
  } else {
    selected <- mutate(selected, From = Evaluator, To = Evaluated)
  }
  
  selected <- selected %>%
    rowwise() %>%
    mutate(Score = sum(c(Rules, Contact, Fair, Attitude, Communication))) %>%
    select(From, To, Score, scoreNames(spiritData))
  
  return(selected)
}

#' Aggregates the self-assessment of the specified team.
#' 
#' @param spiritData Data as read by \code{loadSpiritData}.
#' @param of The team assessing itself.
#' @param average If \code{TRUE}, the self-assessments are averaged.
#'                If \code{FALSE}, all self-assessments are returned.
#' @return A data frame with the (aggregate) score(s) as specified.
selfScore <- function(spiritData, of, average = TRUE) {
  return(score(spiritData, from = of, to = of, average = average) %>% 
           mutate(Of = of) %>% 
           select(Of, Score, scoreNames(spiritData)))
}

#' Computes a basic leaderboard, ordered from highes to lowest total score.
#' 
#' @param spiritData Data as read by \code{loadSpiritData}.
#' @return A data frame with team names and average total (self-)scores.
leaderBoard <- function(spiritData) {
  teams <- teams(spiritData)
  board <- data.frame(team = teams) %>%
    rowwise() %>%
    mutate(spiritScore = score(spiritData, to = team)$Score, 
           selfScore = selfScore(spiritData, of = team)$Score) %>%
    arrange(desc(spiritScore), desc(selfScore))
  
  return(board)
}

#' Computes a basic comparison matrix, showing the (average) score for
#' each pairwise assessment.
#' 
#' @param spiritData Data as read by \code{loadSpiritData}.
#' @return A matrix with average pair-wise scores.
#'          Row labels indiciate the assessor, column labels the assessed.
comparisonMatrix <- function(spiritData) {
  teams <- teams(spiritData)
  m <- sapply(teams, 
              function(t2) sapply(teams, 
                                  function(t1) score(spiritData, from = t1, to = t2, average = T)$Score
                                  )
              )
  colnames(m) <- teams
  rownames(m) <- teams
  return(m)
}
