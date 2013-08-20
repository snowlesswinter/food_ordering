<%@ Language=vbscript %>
<%
    function get_db_connection()
        set get_db_connection = session("db_conn_sess")
    end function
    
    function get_orders()
        dim db_conn
        set db_conn = get_db_connection()
        
        dim records
        set records = server.CreateObject("ADODB.RecordSet")
        
        dim sql_command
        sql_command = "select g.name as guest_name, o.issue_time as order_issue_time, " &_
            "m.name as food_name, m.price as food_price, o.progress as order_progress " &_
            "from food_order as o join guest_book as g " &_
            "on o.guest_id=g.id " &_
            "join food_menu as m " &_
            "on o.food_id=m.id where 1=1" &_
            "order by g.name, o.issue_time desc"

        records.Open sql_command, db_conn
        set get_orders = records
    end function
    
    function get_client_ip_address()
        dim client_ip_addr
        client_ip_addr = request.ServerVariables("HTTP_X_FORWARDED_FOR")
        if client_ip_addr = "" then
            client_ip_addr = request.ServerVariables("REMOTE_ADDR")
        end if
        get_client_ip_address = client_ip_addr
    end function
    
    function extract_date(datetime_string)
        dim offset
        offset = InStr(datetime_string, " ")
        extract_date = Left(datetime_string, offset + 1)
    end function
    
    function extract_time(datetime_string)
        dim extracted
        extracted = Split(datetime_string, " ")
        if ubound(extracted) = 1 then
            extract_time = Split(extracted(1), ":")
        else
            extract_time = array(1)
        end if
    end function
    
    function same_date(time_1, time_2)
        if extract_date(time_1) = extract_date(time_2) then
            same_date = true
        else
            same_date = false
        end if
    end function
    
    function same_issue_time(time_1, time_2)
        dim result
        result = false
        if same_date(time_1, time_2) then
            dim time_parts1, time_parts2
            time_parts1 = extract_time(time_1)
            time_parts2 = extract_time(time_2)
            if ubound(time_parts1) = 2 and ubound(time_parts2) = 2 then
                if time_parts1(0) = time_parts2(0) and time_parts1(1) = time_parts2(1) and _
                        abs(cint(time_parts1(2)) - cint(time_parts2(2))) < 2 then
                    result = true
                end if
            end if
        end if
        same_issue_time = result
    end function
    
    function max(v1, v2)
        if v1 > v2 then
            max = v1
        else
            max = v2
        end if
    end function
    
    function merge_orders(order_records)
        if not IsNull(order_records) and ubound(order_records, 1) = 4 then
            dim row, col
            for row = 0 to ubound(order_records, 2)
                if row < ubound(order_records, 2) then
                    if order_records(0, row) = order_records(0, row + 1) and _
                            same_issue_time(order_records(1, row), order_records(1, row + 1)) then
                        order_records(2, row) = order_records(2, row) & " + " & order_records(2, row + 1)
                        order_records(3, row) = cint(order_records(3, row)) + cint(order_records(3, row + 1))
                        order_records(4, row) = max(order_records(4, row), order_records(4, row + 1))
                        
                        dim i
                        for i = 0 to ubound(order_records, 1)
                            order_records(i, row + 1) = ""
                        next
                    end if
                end if
                
                'status
                dim status
                if order_records(4, row) > "0" then
                    status = "done"
                else
                    status = "pending"
                end if
                order_records(4, row) = status
            next
        end if
        merge_orders = order_records
    end function
    
    function build_order_desc()
        dim order_records
        set order_records = get_orders()
        if order_records.eof then
            build_order_desc = null
        else
            build_order_desc = merge_orders(order_records.GetRows)
        end if
        
        order_records.Close
        set order_records = nothing
    end function
%>
<html>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<head>
    <title>ALL ORDERED</title>
</head>
<body>
    <table>
        <tr>
            <td>
                <a style="text-decoration: underline" href="main.asp">home</a>
            </td>
        </tr>
    </table>
    
    <h1 align="center">All ordered</h1>
    <h3 align="center">by <% = Now %></h3>
    
    <table border="1" align="center">
        <tr>
            <th>Name</th>
            <th>Order Time</th>
            <th>Foods</th>
            <th>Total Amount (￥)</th>
            <th>Status</th>
        </tr>
        <%
            dim order_desc
            order_desc = build_order_desc()
            if not IsNull(order_desc) then
                dim row, col
                for row = 0 to ubound(order_desc, 2)
                    if ubound(order_desc, 1) = 4 and not order_desc(0, row) = "" then
                        response.write("<tr>")
                        
                        dim font1, font2
                        font1 = ""
                        font2 = ""
                        if not order_desc(4, row) = "pending" then
                            font1 = "<font color=""#999999"">"
                            font2 = "</font>"
                        end if
                        
                        for col = 0 to ubound(order_desc, 1)
                            response.write("<td>" & font1 & order_desc(col, row) & font2 & "</td>")
                        next
                        response.write("</tr>")
                    end if
                next
            end if
        %>
    </table>

    <br><br><br><br><br><br><br><br><br><br><br><br><br><br>
    
</body>
</html>