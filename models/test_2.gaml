model test2

global {
    geometry shape <- rectangle(300,300);
    int nb_qiqi_init <- 200;
    rgb group_color <- #lightgreen;
    float qiqi_reproduction_rate <- 0.002;

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

// ===================== QIQI =====================
species qiqi skills: [moving] {
    float size;
    float speed <- 2.0;
    float detect_range <- 30.0;
    float heading <- rnd(360.0);
    rgb color <- #blue;
    bool is_fleeing <- false;

    reflex check_danger {
        list<hutao> nearby_hutao <- hutao where (
            each != nil and
            self distance_to each <= detect_range and
            size < each.diameter
        );

        if (length(nearby_hutao) > 0) {
            is_fleeing <- true;
            color <- #orange;

            hutao threat <- nearby_hutao closest_to self;
            list<baizhu> all_baizhu <- baizhu where (each != nil);

            if (length(all_baizhu) > 0) {
                baizhu nearest_baizhu <- all_baizhu closest_to self;

                float angle_from_hutao <- threat.location towards self.location;
                float angle_to_baizhu  <- self.location towards nearest_baizhu.location;

                float avg_x <- 0.6 * cos(angle_to_baizhu  * #pi / 180)
                             + 0.4 * cos(angle_from_hutao * #pi / 180);
                float avg_y <- 0.6 * sin(angle_to_baizhu  * #pi / 180)
                             + 0.4 * sin(angle_from_hutao * #pi / 180);

                heading <- atan2(avg_y, avg_x) * 180 / #pi;
            } else {
                heading <- threat.location towards self.location;
            }

            do move speed: speed;

        } else {
            is_fleeing <- false;
            color <- #blue;
        }
    }

    reflex wander when: !is_fleeing {
        heading <- heading + rnd(-30, 30);

        float next_x <- location.x + speed * cos(heading * #pi / 180);
        float next_y <- location.y + speed * sin(heading * #pi / 180);

        bool hit_x <- (next_x <= 20.0 or next_x >= world.shape.width - 20.0);
        bool hit_y <- (next_y <= 20.0 or next_y >= world.shape.height - 20.0);

        if (hit_x or hit_y) {
            heading <- heading + 180 + rnd(-15, 15);
        }

        do move speed: speed;
    }

    reflex reproduce {
        if (flip(qiqi_reproduction_rate)) {
            create qiqi number: 1 {
                size <- rnd(1.0, 10.0);
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

// ===================== HUTAO =====================
species hutao skills: [moving] {
    int hit_count <- 0;
    float total_size_lost <- 0.0;
    float diameter <- 4.0;
    float min_diameter <- 2.0;
    float max_diameter <- 25.0;
    rgb color <- #red;
    float speed <- 3.0;
    float normal_speed <- 5.0;
    float boost_speed <- 20.0;
    bool is_in_danger <- false;

    reflex hp_zero when: (diameter <= min_diameter) {
        write "Hutao chết vì hết HP tại chu kỳ " + string(cycle);
        do die;
    }

    reflex move_and_eat {
        // Kiểm tra phạm vi bảo vệ của baizhu
        list<baizhu> nearby_baizhu <- baizhu where (each != nil and self distance_to each <= each.protect_radius);

        if (length(nearby_baizhu) > 0) {
            is_in_danger <- true;
            speed <- boost_speed;
        } else {
            is_in_danger <- false;
            speed <- normal_speed;
        }

        // Di chuyển theo chuột
        if (mouse_location != location) {
            heading <- location towards mouse_location;
            do move speed: speed;
        }

        // Tìm qiqi trong phạm vi va chạm
        list<qiqi> preys <- qiqi where (each != nil and self distance_to each <= diameter / 2.0);

        loop q over: preys {
            if (q.size * sqrt(2.0) < diameter) {
                // ✅ Đủ điều kiện — ăn bình thường
                float prey_size <- q.size;
                ask q { do die; }
                diameter <- min(max_diameter, diameter + prey_size / 2.0);

            } else {
                // ❌ Cố ăn qiqi quá to — bị phạt -1 bán kính
                diameter <- diameter - 1.0;
                write "Hutao cố ăn qiqi quá to tại chu kỳ " + string(cycle) +
                      " → bị giảm bán kính còn " + string(diameter);
                break; // Chỉ phạt 1 lần/chu kỳ
            }
        }

        // Va chạm biên
        float r <- diameter / 4.0;
        bool hit_edge <- (location.x - r <= 3.0 or location.x + r >= world.shape.width or
                          location.y - r <= 3.0 or location.y + r >= world.shape.height);
        if (hit_edge) {
            point map_center <- {world.shape.width / 2.0, world.shape.height / 2.0};
            float angle_to_center <- location towards map_center;
            float push_distance <- 3.0;

            float push_x <- push_distance * cos(angle_to_center * #pi / 180);
            float push_y <- push_distance * sin(angle_to_center * #pi / 180);
            location <- {location.x + push_x, location.y + push_y};

            diameter <- diameter / 2.0;
        }
    }

    aspect base {
        float r <- diameter / 2.0;
        draw circle(r) color: color;

        float hp_percentage <- (diameter - min_diameter) / (max_diameter - min_diameter);
        float hp_bar_width <- 30.0;
        float hp_bar_height <- 4.0;
        point hp_bar_position <- {location.x - hp_bar_width / 2.0, location.y - r - 8.0};

        draw rectangle(hp_bar_width, hp_bar_height) at: hp_bar_position color: #transparent;

        if (hp_percentage > 0) {
            draw rectangle(hp_bar_width * hp_percentage, hp_bar_height)
                 at: {hp_bar_position.x - hp_bar_width / 2.0 + (hp_bar_width * hp_percentage) / 2.0, hp_bar_position.y}
                 color: #green;
        }

        draw rectangle(hp_bar_width, hp_bar_height) at: hp_bar_position color: #transparent border: #black width: 1;

        draw string(int(hp_percentage * 100)) + "%" at: {location.x, location.y - r - 15.0}
             color: #gray font: font("Arial", 8, #bold);
    }
}

// ===================== BAIZHU =====================
species baizhu skills: [moving] {
    float size <- 10.0;
    float speed <- 1.5;
    float normal_speed <- 1.5;
    float chase_speed <- 5.0;
    float protect_radius <- 26.0;
    bool is_chasing <- false;

    reflex protect_against_hutao {
        list<hutao> hutao_in_range <- hutao where (each != nil and self distance_to each <= protect_radius);

        if (length(hutao_in_range) > 0) {
            is_chasing <- true;
            hutao target_hutao <- hutao_in_range[0];

            heading <- location towards target_hutao.location;
            do move speed: chase_speed;

            // Tấn công khi chạm thực sự
            if (self distance_to target_hutao <= self.size / 2.0 + target_hutao.diameter / 2.0) {
                float before <- target_hutao.diameter;
                target_hutao.diameter <- target_hutao.diameter - 2.0;
                target_hutao.hit_count <- target_hutao.hit_count + 1;
                target_hutao.total_size_lost <- target_hutao.total_size_lost + (before - target_hutao.diameter);

                float distance_to_left   <- target_hutao.location.x;
                float distance_to_right  <- world.shape.width - target_hutao.location.x;
                float distance_to_top    <- target_hutao.location.y;
                float distance_to_bottom <- world.shape.height - target_hutao.location.y;
                float min_edge <- min([distance_to_left, distance_to_right, distance_to_top, distance_to_bottom]);

                float angle;
                if (min_edge < 20.0) {
                    point map_center <- {world.shape.width / 2.0, world.shape.height / 2.0};
                    angle <- target_hutao.location towards map_center;
                } else {
                    angle <- rnd(360.0);
                }

                target_hutao.location <- {
                    target_hutao.location.x + 5.0 * cos(angle * #pi / 180),
                    target_hutao.location.y + 5.0 * sin(angle * #pi / 180)
                };
            }
        } else {
            is_chasing <- false;
        }
    }

    reflex wander when: !is_chasing {
        heading <- heading + rnd(-30, 30);

        float next_x <- location.x + normal_speed * cos(heading * #pi / 180);
        float next_y <- location.y + normal_speed * sin(heading * #pi / 180);

        bool hit_x <- (next_x <= 15.0 or next_x >= world.shape.width - 10.0);
        bool hit_y <- (next_y <= 15.0 or next_y >= world.shape.height - 10.0);

        if (hit_x or hit_y) {
            heading <- heading + 180 + rnd(-20, 20);
        }

        do move speed: normal_speed;
    }

    aspect base {
        draw circle(protect_radius) at: location color: rgb(144, 238, 144, 50) border: rgb(0, 128, 0, 100) width: 1;
        draw rectangle(size, size) color: #green border: #darkgreen;
    }
}

// ===================== EXPERIMENT =====================
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