<%@ Language=vbscript %>
<%
    function get_db_connection()
        set get_db_connection = session("db_conn_sess")
    end function
    
    function get_my_orders()
        dim db_conn
        set db_conn = get_db_connection()
        
        dim records
        set records = server.CreateObject("ADODB.RecordSet")
        
        dim sql_command
        sql_command = "select o.issue_time as order_issue_time, m.name as food_name, " &_
            "m.price as food_price, o.progress as order_progress, o.id as order_id " &_
            "from food_order as o join food_menu as m " &_
            "on o.food_id=m.id where o.guest_id in " &_
            "(select id from guest_book where name in "&_
            "(select name from guest_book where ip_addr like '" &_
            get_client_ip_address() & "')) order by o.issue_time desc"

        records.Open sql_command, db_conn
        set get_my_orders = records
    end function
    
    function get_client_ip_address()
        dim client_ip_addr
        client_ip_addr = request.ServerVariables("HTTP_X_FORWARDED_FOR")
        if client_ip_addr = "" then
            client_ip_addr = request.ServerVariables("REMOTE_ADDR")
        end if
        get_client_ip_address = client_ip_addr
    end function
    
    function build_order_desc()
        dim order_records
        set order_records = get_my_orders()
        if order_records.eof then
            build_order_desc = null
        else
            build_order_desc = order_records.GetRows
        end if
        
        order_records.Close
        set order_records = nothing
    end function
    
    function delete_order(order_id)
        dim db_conn
        set db_conn = get_db_connection()

        dim sql_command
        sql_command = "delete from food_order where id=" & order_id

        db_conn.Execute sql_command
    end function
%>
<%
    dim id_to_be_cancelled
    id_to_be_cancelled = request.QueryString("cancel")
    if not id_to_be_cancelled = "" then
        delete_order(id_to_be_cancelled)
    end if
%>
<html>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<head>
    <title>MY ORDERS</title>
</head>
<body>
    <table>
        <tr>
            <td>
                <a style="text-decoration: underline" href="main.asp">home</a>
            </td>
        </tr>
    </table>
    
    <h1 align="center">Submitted orders</h1>
    
    <table border="1" align="center">
        <%
            dim table_headers
            table_headers = "<tr><th>Order Time</th><th>Food</th><th>Price (￥)</th><th>Operation</th></tr>"
        %>
        <% = table_headers %>
        <%
            dim order_desc
            order_desc = build_order_desc()
            if not IsNull(order_desc) then
                dim row, col
                dim first_done
                first_done = true
                for row = 0 to ubound(order_desc, 2)
                    if ubound(order_desc, 1) = 4 and not order_desc(0, row) = "" then
                        dim font1, font2
                        font1 = ""
                        font2 = ""

                        dim cancel_url
                        if order_desc(3, row) < "1" then
                            cancel_url = "<td><a style=""text-decoration: underline"" " &_
                                "href=""my_orders.asp?cancel=" & order_desc(4, row) & """>" &_
                                "<font color=""#0000FF"">Cancel</font></a></td>"
                        else
                            cancel_url = "<td></td>"
                            font1 = "<font color=""#999999"">"
                            font2 = "</font>"
                            if first_done then
                                first_done = false
                                response.write("</table><h3 align=""center"">History</h3>" &_
                                    "<table border=""1"" align=""center"">" & table_headers)
                            end if
                        end if
                        
                        response.write("<tr>")
                        for col = 0 to ubound(order_desc, 1) - 2
                            response.write("<td>" & font1 & order_desc(col, row) & font2 & "</td>")
                        next
                        
                        response.write(cancel_url)
                        response.write("</tr>")
                    end if
                next
            end if
        %>
    </table>
    
    <br><br><br><br><br><br><br><br><br><br><br><br><br><br>
    
</body>
</html>