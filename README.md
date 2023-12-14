# Test program for SQL concurrent data access

## Description

This Genero BDL demo can be used to test SQL commands with two concurrent
programs accessing the same database table rows.
With this sample you can better learn the behavior of an SQL database engine
when concurrent clients modify the same rows.

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

## Test 1: Concurrent updates

1. Make sure to review the DB connection instruction to connect to your DB server.
2. Start two instances of the sqlconcur program
3. In instance A: create_table, insert_into x 5
4. In instance A: begin_work, update_where (row=3) => sets lock
5. In instance B: begin_work, update_where (row=3) => waits for lock (or error)
6. In instance A: commit_work => unlocks row => instance B can do the UPDATE
7. In instance B: commit_work => all updates done without conflict.

## Test 2: Interrupt concurrent updates

1. Make sure to review the DB connection instruction to connect to your DB server.
2. Start two instances of the sqlconcur program
3. In instance A: create_table, insert_into x 5
4. In instance A: begin_work, update_where (row=3) => sets lock
5. In instance B: begin_work, update_where (row=3) => waits for lock (or error)
6. In instance B: hit the interrupt button => error -216 (normal, user interruption)
7. In instance A: commit_work => only one update is done.

