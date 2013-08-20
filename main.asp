<%@ Language=vbscript %>
<%
    function get_db_connection()
        set get_db_connection = session("db_conn_sess")
    end function
    
    function record_new_guest(ip_addr)
        dim db_conn
        set db_conn = get_db_connection()
        
        dim sql_command
        sql_command = "insert into guest_book values ('', '" & ip_addr & "', null, 255)"
        db_conn.execute sql_command
    end function
    
    function get_guest_name(ip_addr)
        dim db_conn
        set db_conn = get_db_connection()
        
        dim records
        set records = server.CreateObject("ADODB.RecordSet")
        
        dim sql_command
        sql_command = "select name from guest_book where ip_addr like '" & ip_addr & "'"

        records.Open sql_command, db_conn
        
        if not records.eof then
            get_guest_name = records("name")
        else
            record_new_guest(ip_addr)
            get_guest_name = ""
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

    function generate_greetings()
        dim client_ip_addr
        client_ip_addr = get_client_ip_address()
        
        dim guest_name
        guest_name = get_guest_name(client_ip_addr)
        
        dim welcome
        if guest_name = "" then
            welcome = "Welcome, stranger"
        else
            welcome = "Welcome back, "
        end if
        
        generate_greetings = welcome & guest_name & ". Your IP address is: " & client_ip_addr
    end function
    
    function get_food_records(provider_id, food_type)
        dim db_conn
        set db_conn = get_db_connection()
        
        dim records
        set records = server.CreateObject("ADODB.RecordSet")
        
        dim sql_command
        sql_command = "select id, name, price, preview_file from food_menu where provider_id=" &_
            provider_id & " and food_type=" & food_type

        records.Open sql_command, db_conn
        set get_food_records = records
    end function
    
    function get_set_meal_records(provider_id)
        set get_set_meal_records = get_food_records(provider_id, 0)
    end function
    
    function get_soup_records(provider_id)
        set get_soup_records = get_food_records(provider_id, 1)
    end function
    
    sub create_food_table(food_records, input_name)
        dim cell_index
        cell_index = 0
        
        dim row_text
        row_text = "var row = null;"
        do until food_records.eof
            row_text = row_text & "row = add_cell(food_table, row, " & cell_index &_
                ", """ & food_records("id") & """, """ & food_records("preview_file") &_
                """, """ & input_name & """, """ & food_records("name") & """, """ &_
                food_records("price") & """);"
            
            cell_index = cell_index + 1
            food_records.MoveNext
        loop
        
        response.write(row_text)
        food_records.close
        set food_records = nothing
    end sub
%>
<html>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<head>
    <title>WELCOME TO ... Uh-Huh!</title>
</head>
<script language="javascript" type="text/javascript" src="/scripts/main.js" charset="utf-8"></script>
<script language="javascript" type="text/javascript">
    <%
        dim known_user
        if get_guest_name(get_client_ip_address()) = "" then
            known_user = "false"
        else
            known_user = "true"
        end if
    %>
    function on_body_loaded() {
        var known_user = <% = known_user %>;
        var delement_to_hide;
        if (known_user) {
            delement_to_hide = "warning_div";
        } else {
            delement_to_hide = "submit_div";
        
            var navigation_table = document.getElementById("navigation_table");
            navigation_table.style.display = "none";
        }
        
        var div = document.getElementById(delement_to_hide);
        div.style.display = "none";
    }
    function on_image_clicked(id) {
        var radio_button = document.getElementById(id);
        radio_button.checked = true
        return false;
    }
</script>
<body onload="on_body_loaded()">
    <table>
        <tr>
            <td>
                <% = generate_greetings() %>
            </td>
            <td align="right">
                The time is now: <% = Now %>
            </td>
        </tr>
    </table>
    <table id="navigation_table">
        <tr>
            <td>
                <a style="text-decoration: underline" href="my_orders.asp">my orders</a>
            </td>
            <td> | </td>
            <td>
                <a style="text-decoration: underline" href="all_ordered.asp">all ordered</a>
            </td>
        </tr>
    </table>
    
    <h1 align="center">Uh-Huh! Food Ordering System</h1>
    
    <form name="Order Food" method="post" action="submit_order.asp" align="center">
        <h3>What would you like to eat today:</h3>
        <p>Set meal:</p>
        <table align="center" id="set_meal_table">
            <script>
                var food_table = get_food_table("set_meal_table");
                <% create_food_table get_set_meal_records(1), "set_meal" %>
            </script>
        </table>
        <p>Soup:</p>
        <table align="center" id="soup_table">
            <script>
                var food_table = get_food_table("soup_table");
                <% create_food_table get_soup_records(1), "soup" %>
            </script>
        </table>
        <div>
            <br><br><br><br><br>
            <div id="submit_div">
                <input type="submit" value="Submit" style="width:200px; height:40px">
            </div>
            <div id="warning_div">
                <font color="red">You need to sign up before submitting orders.</font>
                <br>
                Kindly please go ask the administrator.
            </div>
        </div>
    </form>
    
    <br><br><br><br><br><br><br><br><br><br><br><br><br><br>

</body>
</html>