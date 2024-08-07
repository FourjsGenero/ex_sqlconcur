DEFINE mlog DYNAMIC ARRAY OF RECORD
    ts DATETIME HOUR TO FRACTION(3),
    msg STRING,
    sta INTEGER
END RECORD
DEFINE mlog_att DYNAMIC ARRAY OF RECORD
    ts STRING,
    msg STRING,
    sta STRING
END RECORD

MAIN
    DEFINE x INT
    DEFINE cnt BIGINT
    DEFINE rec RECORD
        k INT,
        c VARCHAR(50)
    END RECORD

    DEFER INTERRUPT
    OPTIONS SQL INTERRUPT ON -- bad practice to set on here, just for testing!

    --DISPLAY "ADD YOUR DATABASE CONNECTION HERE..." EXIT PROGRAM 1
    DATABASE test1

    --SET LOCK MODE TO WAIT 60
    --UPDATE pg_settings SET setting = 5000 WHERE name = 'lock_timeout'

    OPEN FORM f FROM "sqlconcur"
    DISPLAY FORM f

    LET rec.k = 0

    WHENEVER ERROR CONTINUE

    DISPLAY ARRAY mlog TO sr.* ATTRIBUTES(UNBUFFERED, CANCEL = FALSE)

        BEFORE DISPLAY
            CALL DIALOG.setArrayAttributes("sr",mlog_att)

        ON ACTION create_table
            DROP TABLE fjs_tab1
            CREATE TABLE fjs_tab1(k INT NOT NULL PRIMARY KEY, name VARCHAR(50))
            --CREATE TABLE fjs_tab1 ( k INT, name VARCHAR(50) )
            CALL add_log("create table fjs_tab1", sqlca.sqlcode, 0)

        ON ACTION drop_table
            DROP TABLE fjs_tab1
            CALL add_log("drop table fjs_tab1", sqlca.sqlcode, 0)

        ON ACTION set_isolation
            LET int_flag = FALSE
            PROMPT "IFX isolation level (0:DR|1:CR|2:CRLC|3:CS|4:RR):" FOR x
            CALL ui.Interface.refresh()
            IF NOT int_flag THEN
                CASE x
                WHEN 0
                  SET ISOLATION TO DIRTY READ
                  CALL add_log("set isolation to dirty read", sqlca.sqlcode, NULL)
                WHEN 1
                  SET ISOLATION TO COMMITTED READ
                  CALL add_log("set isolation to committed read", sqlca.sqlcode, NULL)
                WHEN 2
                  SET ISOLATION TO COMMITTED READ LAST COMMITTED
                  CALL add_log("set isolation to committed read last committed", sqlca.sqlcode, NULL)
                WHEN 3
                  SET ISOLATION TO CURSOR STABILITY
                  CALL add_log("set isolation to cursor stability", sqlca.sqlcode, NULL)
                WHEN 4
                  SET ISOLATION TO REPEATABLE READ
                  CALL add_log("set isolation to repeatable read", sqlca.sqlcode, NULL)
                END CASE
            END IF

        ON ACTION set_lock_wait
            LET int_flag = FALSE
            PROMPT "Enter lock wait seconds (<0 = not wait, 0 = wait inf):" FOR x
            CALL ui.Interface.refresh()
            IF NOT int_flag THEN
                CASE
                WHEN x < 0
                    SET LOCK MODE TO NOT WAIT
                    CALL add_log(
                        "lock mode set to not wait", sqlca.sqlcode, NULL)
                WHEN x == 0
                    SET LOCK MODE TO WAIT
                    CALL add_log("lock mode set to wait", sqlca.sqlcode, NULL)
                WHEN x > 0
                    SET LOCK MODE TO WAIT x
                    CALL add_log(
                        SFMT("lock mode set to %1", x), sqlca.sqlcode, NULL)
                END CASE
            END IF

        ON ACTION select_row
            LET int_flag = FALSE
            PROMPT "Enter key of the row to select:" FOR rec.k
            CALL ui.Interface.refresh()
            IF NOT int_flag THEN
               SELECT name INTO rec.c FROM fjs_tab1 WHERE k = rec.k
               CALL add_log("select name from fjs_tab1", sqlca.sqlcode, rec.c)
            END IF

        ON ACTION select_count
            SELECT COUNT(*) INTO x FROM fjs_tab1
            CALL add_log("select count(*) from fjs_tab1", sqlca.sqlcode, x)

        ON ACTION begin_work
            BEGIN WORK
            CALL add_log("begin work", sqlca.sqlcode, NULL)

        ON ACTION insert_into
            LET rec.k = get_max_k() + 1
            LET rec.c = SFMT("item_%1", rec.k)
            INSERT INTO fjs_tab1 VALUES(rec.*)
            CALL add_log(
                SFMT("insert into fjs_tab1 values (%1,'item_%1')", rec.k),
                sqlca.sqlcode,
                NULL)

        ON ACTION insert_many
            LET int_flag = FALSE
            PROMPT "Number of rows to insert:" FOR cnt
            CALL ui.Interface.refresh()
            IF NOT int_flag THEN
                LET rec.k = get_max_k()
                FOR x=1 TO cnt
                    LET rec.k = rec.k + 1
                    LET rec.c = SFMT("item_%1", rec.k)
                    INSERT INTO fjs_tab1 VALUES(rec.*)
                    IF int_flag THEN EXIT FOR END IF
                END FOR
                CALL add_log( SFMT("%1 rows inserted.", cnt), sqlca.sqlcode, NULL)
            END IF

        ON ACTION select_for_update
            --ATTRIBUTES(COMMENT = "THIS IS INVALID (FGL-3585)!")
            LET int_flag = FALSE
            PROMPT "Enter key of the row to update:" FOR rec.k
            CALL ui.Interface.refresh()
            IF NOT int_flag THEN
                LET rec.c = CURRENT FRACTION TO FRACTION(3)
                SELECT * FROM fjs_tab1 WHERE k = rec.k FOR UPDATE
                CALL add_log(
                    SFMT("select * from fjs_tab1 for update ... where k=%1", rec.k),
                    sqlca.sqlcode,
                    NULL)
            END IF

        ON ACTION udpate_where
            LET int_flag = FALSE
            PROMPT "Enter key of the row to update:" FOR rec.k
            CALL ui.Interface.refresh()
            IF NOT int_flag THEN
                LET rec.c = CURRENT FRACTION TO FRACTION(3)
                UPDATE fjs_tab1 SET name = rec.c WHERE k = rec.k
                CALL add_log(
                    SFMT("update fjs_tab1 ... where k=%1", rec.k),
                    sqlca.sqlcode,
                    NULL)
            END IF

        ON ACTION delete_where
            LET int_flag = FALSE
            PROMPT "Enter key of the row to update:" FOR rec.k
            CALL ui.Interface.refresh()
            IF NOT int_flag THEN
                DELETE FROM fjs_tab1 WHERE k = rec.k
                CALL add_log(sfmt("delete from fjs_tab1 where k=%1",rec.k), sqlca.sqlcode, NULL)
            END IF

        ON ACTION force_sql_error
            DELETE FROM unexisting_table
            CALL add_log("Invalid SQL = erro", sqlca.sqlcode, NULL)

        ON ACTION commit_work
            COMMIT WORK
            CALL add_log("commit work", sqlca.sqlcode, NULL)

        ON ACTION rollback_work
            ROLLBACK WORK
            CALL add_log("rollback work", sqlca.sqlcode, NULL)

        ON ACTION forupd_declare
            DECLARE c_fu CURSOR
                --  Why (k = ? or k = k + ?) ?
                --     with 5 => where (k=5 or k=k+5) => only row 5
                --     with 0 => where (k=0 or k=k+0) => all rows
                FOR SELECT * FROM fjs_tab1 WHERE (k = ? OR k = k + ?) FOR UPDATE
                --FROM "SELECT * FROM fjs_tab1 WHERE (k = ? OR k = k + ?) FOR UPDATE NOWAIT"

            CALL add_log("declare for udpate cursor", sqlca.sqlcode, NULL)
        ON ACTION forupd_open -- must be in TX
            LET int_flag = FALSE
            PROMPT "Enter key of the row to select (0 for all):" FOR rec.k
            CALL ui.Interface.refresh()
            IF NOT int_flag THEN
                OPEN c_fu USING rec.k, rec.k
                CALL add_log("open for udpate cursor", sqlca.sqlcode, NULL)
            END IF
        ON ACTION forupd_fetch
            FETCH c_fu INTO rec.*
            CALL add_log(
                SFMT("fetch for udpate cursor: k=%1", rec.k),
                sqlca.sqlcode,
                rec.k)
        ON ACTION forupd_update_wco
            LET rec.c = CURRENT FRACTION TO FRACTION(3)
            UPDATE fjs_tab1 SET name = rec.c WHERE CURRENT OF c_fu
            CALL add_log("update fjs_tab1 ... where current of", sqlca.sqlcode, NULL)
        ON ACTION forupd_close
            CLOSE c_fu
            CALL add_log("close for udpate cursor", sqlca.sqlcode, NULL)
        ON ACTION forupd_free
            FREE c_fu
            CALL add_log("free for udpate cursor", sqlca.sqlcode, NULL)

        ON ACTION long_query
--options sql interrupt on
            CALL add_log("starting long query...", 0, NULL)
            CALL ui.Interface.refresh()

{ MySQL
            SELECT DISTINCT benchmark(1000000000, md5('when will it end?'))
                FROM fjs_tab1
}

           select count(*) into cnt from
                  fjs_tab1 t1a01, fjs_tab1 t1a02, fjs_tab1 t1a03, fjs_tab1 t1a04, fjs_tab1 t1a05,
                  fjs_tab1 t1a06, fjs_tab1 t1a07, fjs_tab1 t1a08, fjs_tab1 t1a09, fjs_tab1 t1a10
                  ,fjs_tab1 t1a11, fjs_tab1 t1a12, fjs_tab1 t1a13, fjs_tab1 t1a14, fjs_tab1 t1a15
                  ,fjs_tab1 t1a16, fjs_tab1 t1a17, fjs_tab1 t1a18, fjs_tab1 t1a19, fjs_tab1 t1a20

--options sql interrupt off


            CALL add_log("after long query", sqlca.sqlcode, NULL)

        ON ACTION close EXIT DISPLAY

    END DISPLAY

    WHENEVER ERROR STOP

END MAIN

FUNCTION add_log(msg STRING, sta INTEGER, val INTEGER) RETURNS ()
    DEFINE x INTEGER
    DEFINE d ui.Dialog
    LET x = mlog.getLength() + 1
    LET mlog[x].ts = CURRENT HOUR TO FRACTION(3)
    LET mlog[x].msg = msg
    LET mlog[x].sta = sta
    LET mlog_att[x].sta = IIF(sta<0, "red reverse", NULL)
    DISPLAY NULL TO info
    IF val IS NOT NULL THEN
        DISPLAY SFMT("val=%1", val) TO info
    END IF
    IF sta < 0 THEN
        DISPLAY SFMT("(%1) %2 SQLSTATE=%3", sqlca.sqlerrd[2], SQLERRMESSAGE, SQLSTATE) TO info
    END IF
    LET d = ui.Dialog.getCurrent()
    CALL d.setCurrentRow("sr", x)
END FUNCTION

FUNCTION get_max_k() RETURNS BIGINT
    DEFINE m BIGINT
    WHENEVER ERROR CONTINUE
    SELECT MAX(k) INTO m FROM fjs_tab1
    WHENEVER ERROR STOP
    RETURN NVL(m,0)
END FUNCTION
