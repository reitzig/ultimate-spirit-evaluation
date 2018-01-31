You find here R functions for summarizing spirit scores for Ultimate tournaments.
It is based on the 
    [method the WFDF uses](http://www.wfdf.org/sotg/spirit-rules-a-scoring).

## Quickstart

Very quickly, here is how you summarize all the data:

~~~R
> spiritData <- loadSpiritData("example/example-tournament.csv")

> leaderBoard(spiritData)
      team spiritScore selfScore
1 Floaters        10.5      10.0
2  Discers        10.0      10.5
3 Cleaters         9.0       9.5

> comparisonMatrix(spiritData)
         Cleaters Discers Floaters
Cleaters      9.5    11.0       10
Discers       8.0    10.5       11
Floaters     10.0     9.0       10
~~~

Here, all entries are average scores.


## Documentation

### Basic Use

The script expects the raw data to be assembled in a CSV file.
It has to have columns `Team1`, `Team2`, `Evaluator`, and `Evaluated`;
the first two identify the game (so you'd have four rows with the same 
values here for each game), the other two whom scored whom.

For [example](https://github.com/reitzig/ultimate-spirit-evaluation/blob/master/example/example-tournament.csv):

~~~
Team1,Team2,Evaluator,Evaluated,Rules,Contact,Fair,Attitude,Communication
Discers,Floaters,Discers,Floaters,2,3,2,2,2
Discers,Floaters,Discers,Discers,2,2,2,1,2
Discers,Floaters,Floaters,Discers,1,2,2,2,2
Discers,Floaters,Floaters,Floaters,2,2,2,2,2
Cleaters,Floaters,Cleaters,Floaters,2,2,1,2,3
Cleaters,Floaters,Cleaters,Cleaters,3,2,2,2,1
Cleaters,Floaters,Floaters,Cleaters,2,2,2,2,2
Cleaters,Floaters,Floaters,Floaters,2,2,2,2,2
Cleaters,Discers,Cleaters,Discers,3,2,1,2,3
Cleaters,Discers,Cleaters,Cleaters,3,1,2,2,1
Cleaters,Discers,Discers,Cleaters,2,1,1,2,2
Cleaters,Discers,Discers,Discers,2,3,3,2,2
~~~

Now, to get started you need to load the data into your R session (or script):

~~~R
> source("evaluate-spirit.R")
> spiritData <- loadSpiritData("example/example-tournament.csv")
> spiritData
      Team1    Team2 Evaluator Evaluated Rules Contact Fair Attitude Communication
1   Discers Floaters   Discers  Floaters     2       3    2        2             2
2   Discers Floaters   Discers   Discers     2       2    2        1             2
3   Discers Floaters  Floaters   Discers     1       2    2        2             2
4   Discers Floaters  Floaters  Floaters     2       2    2        2             2
5  Cleaters Floaters  Cleaters  Floaters     2       2    1        2             3
6  Cleaters Floaters  Cleaters  Cleaters     3       2    2        2             1
7  Cleaters Floaters  Floaters  Cleaters     2       2    2        2             2
8  Cleaters Floaters  Floaters  Floaters     2       2    2        2             2
9  Cleaters  Discers  Cleaters   Discers     3       2    1        2             3
10 Cleaters  Discers  Cleaters  Cleaters     3       1    2        2             1
11 Cleaters  Discers   Discers  Cleaters     2       1    1        2             2
12 Cleaters  Discers   Discers   Discers     2       3    3        2             2
~~~

Here we see spirit scores for three games. Each game produces four rows since
both teams assess themselves and the other team, respectively.

You can access the teams and score categories as follows:

~~~R
> teams(spiritData)
[1] "Cleaters" "Discers" "Floaters"
> scoreNames(spiritData)
[1] "Rules" "Contact" "Fair" "Attitude" "Communication"
~~~

The central function is `score(...)`. You can use it to filter and summarize 
multiple assessments. Here are some usage examples:

~~~R
> score(spiritData, from = "Cleaters")
      From    To Score Rules Contact  Fair Attitude Communication
1 Cleaters    NA  10.5   2.5       2     1        2             3

> score(spiritData, from = "Cleaters", average = FALSE)
      From       To Score Rules Contact  Fair Attitude Communication
1 Cleaters Floaters    10     2       2     1        2             3
2 Cleaters  Discers    11     3       2     1        2             3

> score(spiritData, to = "Cleaters")
   From       To Score Rules Contact  Fair Attitude Communication
1    NA Cleaters     9     2     1.5   1.5        2             2

> score(spiritData, from = "Floaters", to = "Cleaters")
      From       To Score Rules Contact  Fair Attitude Communication
1 Floaters Cleaters    10     2       2     2        2             2
~~~

There is a helper function `selfScore(...)` that calls `score(...)` with 
parameters `from` and `to` set to the same team; self-explanatory.

### Creating presentable documents

You can use knitr to create HTML and PDF documents presenting the scores.
Find example 
    [code here](https://github.com/reitzig/ultimate-spirit-evaluation/blob/master/example/example-summary.Rmd)
and
    [website here](https://htmlpreview.github.io/?https://github.com/reitzig/ultimate-spirit-evaluation/blob/master/example/example-summary.html).
There are few limits to what you can do -- if you know your way around R.

### Advantages over spreadsheets

Most spirit evaluation I've seen were made by hand (which is slow an error-prone)
or using spreadsheets. Here are some advantages of a scripted solution:

 * Robust and testable -- the same function is used for all data; you can all too
   easily mess up _one_ of the many individual formulae in a spreadsheet.
 * It scales better to large numbers of teams and games.
 * More flexible -- the number of teams and games does not matter; it's easy to
   customize the scoring categories.
 * Data analysis -- the power of R is at your beck and call. Does the game outcome
   correlate with spirit? Are there teams that consistently self-score higher
   then other teams score them? Are there trends over time?
