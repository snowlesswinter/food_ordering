<%@ Language = vbscript %>
<%
    function get_db_connection()
        set get_db_connection = session("db_conn_sess")
    end function
    
    function get_guest_id(ip_addr)
        dim db_conn
        set db_conn = get_db_connection()
        
        dim records
        set records = server.CreateObject("ADODB.RecordSet")
        
        dim sql_command
        sql_command = "select id from guest_book where ip_addr like '" & ip_addr & "'"

        records.Open sql_command, db_conn
        
        if not records.eof then
            get_guest_id = records("id")
        else
            get_guest_id = ""
        end if
        
        records.close
        set records = nothing
    end function
    
    function get_client_ip_address()
        dim client_ip_addr
        client_ip_addr = request.ServerVariables("HTTP_X_FORWARDED_FOR")
        if client_ip_addr = "" then
            client_ip_addr = request.ServerVariables("REMOTE_ADDR")
        end if
        get_client_ip_address = client_ip_addr
    end function
    
    function make_order(type_string)
        dim food_id
        food_id = request.form(type_string)
        
        if food_id = "" then
            make_order = true
            exit function
        end if
    
        dim db_conn
        set db_conn = get_db_connection()
        
        dim guest_id
        guest_id = get_guest_id(get_client_ip_address())
        
        if guest_id = "" then
            make_order = false
            exit function
        end if

        dim sql_command
        const provider_id = 1
        const progress = 0
        sql_command = "insert into food_order (guest_id, food_id, issue_time, progress) values (" &_
            guest_id & ", " & food_id & ", GETDATE()," & progress & ")"

        db_conn.execute(sql_command)
        make_order = true
    end function
    
    function load_food_record_by_id(provider_id, food_id)
        dim db_conn
        set db_conn = get_db_connection()
        
        dim records
        set records = server.CreateObject("ADODB.RecordSet")
        
        dim sql_command
        sql_command = "select name, price from food_menu where id=" & food_id

        records.Open sql_command, db_conn
        set load_food_record_by_id = records
    end function
    
    function load_food_record(type_string)
        dim food_id
        food_id = request.form(type_string)
        
        if not food_id = "" then
            set load_food_record = load_food_record_by_id(1, food_id)
        else
            set load_food_record = nothing
        end if
    end function
    
    function load_set_meal_order_record()
        set load_set_meal_order_record = load_food_record("set_meal")
    end function

    function load_soup_order_record()
        set load_soup_order_record = load_food_record("soup")
    end function

    function build_order_desc(set_meal_order, soup_order)
        dim set_meal_desc
        if not set_meal_order is nothing then
            if not set_meal_order.eof then
                set_meal_desc = set_meal_order("name") & "   ￥" & set_meal_order("price")
            end if
        else
            set_meal_desc = ""
        end if
        
        dim soup_desc
        if not soup_order is nothing then
            if not soup_order.eof then
                soup_desc = soup_order("name") & "   ￥" & soup_order("price")
            end if
        else
            soup_desc = ""
        end if
        
        dim operator
        if set_meal_desc = "" or soup_desc = "" then
            operator = ""
        else
            operator = " + "
        end if 
        
        build_order_desc = set_meal_desc & operator & soup_desc
    end function
%>
<%
    dim redirect
    redirect = false
    if request.form("set_meal") = "" and request.form("soup") = "" then
        redirect = true
        response.redirect("my_orders.asp")
    end if
%>
<html>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<head>
    <title>SUBMIT</title>
</head>
<body>
    <h5 align="center">
        <%
            if not redirect then
                dim make_succeeded
                make_succeeded = true
                
                if not make_order("set_meal") then
                    make_succeeded = false
                end if
                
                if not make_order("soup") then
                    make_succeeded = false
                end if
                
                if not make_succeeded then
                    response.write("Failed to make order.")
                else
                    response.write("Your have submitted the following order(s):")
                end if
            end if
        %>
    </h5>
    
    <h3 align="center">
        <%
            if not redirect then
                if make_succeeded then
                    dim set_meal_order
                    set set_meal_order = load_set_meal_order_record()
                    
                    dim soup_order
                    set soup_order = load_soup_order_record()
                    
                    response.write(build_order_desc(set_meal_order, soup_order))
                    
                    set_meal_order.Close
                    set set_meal_order = nothing
                    soup_order.Close
                    set soup_order = nothing
                end if
            end if
        %>
    </h3>
    <p align="center">
        <a style="text-decoration: underline" href="my_orders.asp">View what I have ordered</a>
    </p>
    
</body>
</html>