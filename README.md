# Test program for SQL concurrent data access

## Description

This Genero BDL demo can be used to test SQL commands with two concurrent
programs accessing the same database table rows.

![Genero program launcher (GDC)](https://github.com/FourjsGenero/ex_sqlconcur/raw/master/docs/sqlconcur-screen-001.png)

## Prerequisites

* Genero BDL 3.20+
* Genero Browser Client 1.00.52+
* Genero Desktop Client 3.20+
* Genero Studio 3.20+
* GNU Make

## Setup the test program

Before compiling, modify the program to connect to your database.

## Compilation from command line

1. make clean all
2. make run

## Compilation in Genero Studio

1. Load the sqlconcur.4pw project
2. Build the project

