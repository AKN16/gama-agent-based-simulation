model test2

global {
    geometry shape <- rectangle(300,300);
    int nb_qiqi_init <- 200;
    rgb group_color <- #lightgreen;
    float qiqi_reproduction_rate <- 0.002; // Tỉ lệ sinh sản của qiqi

    int nb_qiqi -> {length(qiqi)};
    int nb_hutao -> {length(hutao)};
    point mouse_location <- {0, 0};

    init {
        create qiqi number: nb_qiqi_init {
            size <- rnd(1.0, 10.0);
            location <- {rnd(5.0, world.shape.width - 5.0), rnd(5.0, world.shape.height - 5.0)};
        }

        create hutao number: 1 {
            location <- {world.shape.width / 2.0, world.shape.height / 2.0};
        }
        
        create baizhu number: 15 {
            point center <- {world.shape.width / 2.0, world.shape.height / 2.0};
            point spawn_location;
            
            // Tìm vị trí sinh cách xa trung tâm ít nhất 50 pixel
            loop while: true {
                spawn_location <- {rnd(10.0, world.shape.width - 10.0), rnd(10.0, world.shape.height - 10.0)};
                if (spawn_location distance_to center > 50.0) {
                    break;
                }
            }
            
            location <- spawn_location;
        }
		
    }

    reflex stop_simulation when: (nb_qiqi = 0) {
        write "Chương trình kết thúc: Hết qiqi!";
        do pause;
    }
    
    reflex stop_simulation_hutao_dead when: (nb_hutao = 0) {
        write "Chương trình kết thúc: Hutao đã chết!";
        do pause;
    }
}

species qiqi skills: [moving] {
    float size;
    float speed <- 2.0;
    float heading <- rnd(360.0);
    rgb color <- #blue;

    reflex wander {
        heading <- heading + rnd(-30, 30);

        // Dự đoán vị trí tiếp theo
        float next_x <- location.x + speed * cos(heading * #pi / 180);
        float next_y <- location.y + speed * sin(heading * #pi / 180);

        bool hit_x <- (next_x <= 20.0 or next_x >= world.shape.width-20.0);
        bool hit_y <- (next_y <= 20.0 or next_y >= world.shape.height-20.0);

        if (hit_x or hit_y) {
            heading <- heading + 180 + rnd(-15, 15); // Bị đẩy ngược + hơi ngẫu nhiên
        }

        do move speed: speed;
    }

    reflex reproduce {
        if (flip(qiqi_reproduction_rate)) {
            // Sinh ra qiqi mới gần vị trí hiện tại
            create qiqi number: 1 {
                size <- rnd(1.0, 10.0);
                // Sinh ra trong phạm vi 20 pixel xung quanh qiqi cha mẹ
                location <- {
                    max(5.0, min(world.shape.width - 5.0, myself.location.x + rnd(-20.0, 20.0))),
                    max(5.0, min(world.shape.height - 5.0, myself.location.y + rnd(-20.0, 20.0)))
                };
            }
        }
    }

    aspect base {
        draw rectangle(size, size) color: color;
    }
}


species hutao skills: [moving] {
	int hit_count <- 0;           // Số lần bị đánh
	float total_size_lost <- 0.0; // Tổng kích thước đã bị trừ
    float diameter <- 4.0;
    float min_diameter <- 2.0;
    float max_diameter <- 25.0;
    rgb color <- #red;
    float speed <- 3.0;
    float normal_speed <- 3.0;
    float boost_speed <- 15.0;
    bool is_in_danger <- false;   // Có đang trong phạm vi bảo vệ của baizhu không

    reflex move_and_eat {
        // Kiểm tra xem có đang trong phạm vi bảo vệ của baizhu nào không
        list<baizhu> nearby_baizhu <- baizhu where (each != nil and self distance_to each <= each.protect_radius);
        
        if (length(nearby_baizhu) > 0) {
            // Đang trong phạm vi bảo vệ - tăng tốc
            is_in_danger <- true;
            speed <- boost_speed;
        } else {
            // Không còn trong phạm vi bảo vệ nào - về tốc độ bình thường
            is_in_danger <- false;
            speed <- normal_speed;
        }
        
        // Di chuyển theo chuột
        if (mouse_location != location) {
            heading <- location towards mouse_location;
            do move speed: speed;
        }

        // Tìm qiqi nằm trong phạm vi ăn được
        list<qiqi> preys <- qiqi where (each != nil and self distance_to each <= diameter / 2);

        loop q over: preys {
            float d_cheo_q <- sqrt(q.size^2 + q.size^2);
            if (d_cheo_q <= diameter) {
                float prey_size <- q.size;
                q.size <- 0.0;
                ask q { do die; }

                diameter <- min(max_diameter, diameter + (prey_size / 2.0));
            }
        }

        // Va chạm biên
        float r <- diameter / 4.0;
        bool hit_edge <- (location.x - r <= 3.0 or location.x + r >= world.shape.width or
                          location.y - r <= 3.0 or location.y + r >= world.shape.height);
        if (hit_edge) {
            // Đẩy hutao về tâm bản đồ
            point map_center <- {world.shape.width / 2.0, world.shape.height / 2.0};
            float angle_to_center <- location towards map_center;
            float push_distance <- 3.0; // Khoảng cách đẩy
            
            float push_x <- push_distance * cos(angle_to_center * #pi / 180);
            float push_y <- push_distance * sin(angle_to_center * #pi / 180);
            location <- {location.x + push_x, location.y + push_y};
            
            // Vẫn giảm kích thước khi chạm biên
            diameter <- diameter / 2.0;
            if (diameter < min_diameter) {
                write "hutao chết vì đường kính quá nhỏ (< " + string(min_diameter) +
                      ") sau khi chạm biên tại chu kỳ " + string(cycle);
                do die;
            }
        }
    }

    aspect base {
    	float r <- diameter / 2.0;
        draw circle(r) color: color;
        
        // Vẽ thanh HP
        float hp_percentage <- (diameter - min_diameter) / (max_diameter - min_diameter);
        float hp_bar_width <- 30.0;
        float hp_bar_height <- 4.0;
        point hp_bar_position <- {location.x - hp_bar_width/2.0, location.y - r - 8.0};
        
        // Vẽ nền thanh HP (màu đỏ)
        draw rectangle(hp_bar_width, hp_bar_height) at: hp_bar_position color: #transparent;
        
        // Vẽ HP hiện tại (màu xanh lá)
        if (hp_percentage > 0) {
            draw rectangle(hp_bar_width * hp_percentage, hp_bar_height) 
                 at: {hp_bar_position.x - hp_bar_width/2.0 + (hp_bar_width * hp_percentage)/2.0, hp_bar_position.y} 
                 color: #green;
        }
        
        // Vẽ viền thanh HP
        draw rectangle(hp_bar_width, hp_bar_height) at: hp_bar_position color: #transparent border: #black width: 1;
        
        // Hiển thị thông tin HP bằng số
        draw string(int(hp_percentage * 100)) + "%" at: {location.x, location.y - r - 15.0} 
             color: #gray font: font("Arial", 8, #bold);
    }
}


species baizhu skills: [moving] {
    float size <- 10.0;
    float speed <- 1.5;
    float attack_range <- 26.0;
    float protect_radius <- 26.0; // bán kính vùng bảo vệ

    reflex protect_against_hutao {
        // Tìm hutao trong phạm vi bảo vệ (chỉ có 1 hutao)
        list<hutao> hutao_in_range <- hutao where (each != nil and self distance_to each <= protect_radius);

        if (length(hutao_in_range) > 0) {
            // Lấy hutao duy nhất để tấn công
            hutao target_hutao <- hutao_in_range[0];
            
            // Di chuyển về phía hutao
            heading <- location towards target_hutao.location;
            speed <- 5.0; // Tăng tốc khi tấn công
            do move speed: speed;

            // Kiểm tra xem có thể tấn công không
            if (self distance_to target_hutao <= self.size + target_hutao.diameter / 2.0 + attack_range) {
                float before <- target_hutao.diameter;
                target_hutao.diameter <- target_hutao.diameter - 2.0;
                float lost <- before - target_hutao.diameter;
                target_hutao.hit_count <- target_hutao.hit_count + 1;
                target_hutao.total_size_lost <- target_hutao.total_size_lost + lost;
                
                // Kích hoạt tăng tốc cho hutao (không cần thiết nữa vì đã tự động tăng tốc)
                // target_hutao.boost_start_cycle <- cycle;
                // target_hutao.speed <- target_hutao.boost_speed;

                // Kiểm tra xem hutao có gần biên không (khoảng cách < 30.0 từ tâm đến biên)
                float distance_to_left <- target_hutao.location.x;
                float distance_to_right <- world.shape.width - target_hutao.location.x;
                float distance_to_top <- target_hutao.location.y;
                float distance_to_bottom <- world.shape.height - target_hutao.location.y;
                
                float min_distance_to_edge <- min([distance_to_left, distance_to_right, distance_to_top, distance_to_bottom]);
                
                float angle;
                if (min_distance_to_edge < 20.0) {
                    // Gần biên - bật về tâm map
                    point map_center <- {world.shape.width / 2.0, world.shape.height / 2.0};
                    angle <- target_hutao.location towards map_center;
                } else {
                    // Không gần biên - bật ngẫu nhiên
                    angle <- rnd(360.0);
                }
                
                float push_x <- 5.0 * cos(angle * #pi / 180);
                float push_y <- 5.0 * sin(angle * #pi / 180);
                target_hutao.location <- {target_hutao.location.x + push_x, target_hutao.location.y + push_y};
                
                // Nếu sau khi bị đánh, hutao chết vì nhỏ quá
                if (target_hutao.diameter < target_hutao.min_diameter) {
                    write "hutao bị Baizhu đánh chết tại chu kỳ " + string(cycle);
                    ask target_hutao { do die; }
                }
            }
        } else {
            // Không có hutao trong phạm vi - quay về tốc độ bình thường
            speed <- 1.5;
        }
    }
    
    reflex wander {
        heading <- heading + rnd(-30, 30);

        // Dự đoán vị trí tiếp theo
        float next_x <- location.x + speed * cos(heading * #pi / 180);
        float next_y <- location.y + speed * sin(heading * #pi / 180);

        bool hit_x <- (next_x <= 15.0 or next_x >= world.shape.width - 10.0);
        bool hit_y <- (next_y <= 15.0 or next_y >= world.shape.height - 10.0);

        if (hit_x or hit_y) {
            heading <- heading + 180 + rnd(-20, 20); // Bị đẩy ngược + hơi ngẫu nhiên
        }

        do move speed: speed;
    }
    

    aspect base {
        // Vẽ vùng bảo vệ
        draw circle(protect_radius) at: location color: rgb(144, 238, 144, 50) border: rgb(0, 128, 0, 100) width: 1;

        // Vẽ hình vuông baizhu
        draw rectangle(size, size) color: #green border: #darkgreen;
    }
}


experiment qiqi_experiment type: gui {
    parameter "Số lượng qiqi ban đầu: " var: nb_qiqi_init min: 50 max: 500 category: "Khởi tạo";
    parameter "Tỉ lệ sinh sản qiqi: " var: qiqi_reproduction_rate min: 0.0 max: 1.0 category: "Sinh sản";

    output {
        display main_display {
            event #mouse_move {
                ask world {
                    mouse_location <- #user_location;
                }
            }

            species qiqi aspect: base;
            species hutao aspect: base;
            species baizhu aspect: base;
        }

        monitor "Số lượng qiqi hiện tại" value: nb_qiqi;
    }
}