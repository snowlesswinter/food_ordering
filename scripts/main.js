function get_food_table(table_id) {
    return document.getElementById(table_id);
}

function add_cell(table, row, index, id, preview_file, submit_type, input_name, price) {
    var current_row = row

    // we'll begin a new row every 5 cells
    if (!(index % 5)) {
        current_row = document.createElement("tr");
        table.appendChild(current_row);
    }
    var cell = document.createElement("td");
    var image = document.createElement("img");
    image.width = 200;
    image.height = 160;
    image.src = "/images/" + preview_file + ".jpg";
    image.setAttribute("onclick", "on_image_clicked(" + id + ")");
    
    cell.appendChild(image);
    
    var line_breaker = document.createElement("br");
    cell.appendChild(line_breaker);
    
    var input = document.createElement("input");
    input.type = "radio";
    input.name = submit_type;
    input.value = id;
    input.id = id;
    
    cell.appendChild(input);
    
    var radio_text = document.createTextNode(input_name + "   ￥" + price);
    
    cell.appendChild(radio_text);
    
    current_row.appendChild(cell);
    return current_row;
}