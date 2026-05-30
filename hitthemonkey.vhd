library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity HitTheMonkey is
    Port ( clk  : in STD_LOGIC;
           sw   : in STD_LOGIC_VECTOR (15 downto 0);
           btnC : in STD_LOGIC;
           btnU : in STD_LOGIC;
           led  : out STD_LOGIC_VECTOR (15 downto 0);
           seg  : out STD_LOGIC_VECTOR (6 downto 0);
           dp   : out STD_LOGIC;
           an   : out STD_LOGIC_VECTOR (3 downto 0));
end HitTheMonkey;

architecture Behavioral of HitTheMonkey is
    -- Divizoare de ceas
    signal tick_cnt     : integer := 0;
    signal tick_max     : integer := 20000000;
    signal refresh_cnt  : integer := 0;
    signal pwm_tick_cnt : integer := 0;
    signal pwm_cnt      : integer range 0 to 3 := 0;

    -- FSM si coada luminoasa
    signal pos    : integer range 0 to 15 := 0;
    signal pos_t1 : integer range 0 to 15 := 0;
    signal pos_t2 : integer range 0 to 15 := 0;
    signal pos_t3 : integer range 0 to 15 := 0;
    signal dir    : integer range -1 to 1 := 1;

    -- Sistem scor
    signal score0 : integer range 0 to 9 := 0;
    signal score1 : integer range 0 to 9 := 0;
    signal score2 : integer range 0 to 9 := 0;
    signal score3 : integer range 0 to 9 := 0;
    signal total_hits : integer := 0;

    -- Edge detector buton
    signal btnC_reg, btnC_last, btnC_pulse : std_logic := '0';
    signal hit_done : boolean := false;

    -- Multiplexare 7 segmente
    signal active_digit : integer range 0 to 3 := 0;
    signal current_val  : integer range 0 to 9 := 0;
begin
    dp <= '1';

    -- Proces principal: logica joc
    process(clk)
    begin
        if rising_edge(clk) then
            btnC_reg <= btnC;
            btnC_last <= btnC_reg;
            btnC_pulse <= btnC_reg and not btnC_last;

            if btnU = '1' then
                pos <= 0; dir <= 1;
                pos_t1 <= 0; pos_t2 <= 0; pos_t3 <= 0;
                tick_cnt <= 0;
                tick_max <= 20000000;
                score0 <= 0; score1 <= 0; score2 <= 0; score3 <= 0;
                total_hits <= 0;
                hit_done <= false;
            else
                if tick_cnt >= tick_max then
                    tick_cnt <= 0;
                    hit_done <= false;

                    pos_t3 <= pos_t2;
                    pos_t2 <= pos_t1;
                    pos_t1 <= pos;

                    if dir = 1 then
                        if pos = 14 then
                            pos <= 15; dir <= -1;
                        else
                            pos <= pos + 1;
                        end if;
                    else
                        if pos = 1 then
                            pos <= 0; dir <= 1;
                        else
                            pos <= pos - 1;
                        end if;
                    end if;
                else
                    tick_cnt <= tick_cnt + 1;
                end if;

                if btnC_pulse = '1' and not hit_done then
                   if sw(pos)='1' or
                   sw(pos_t1)='1' or
                   sw(pos_t2)='1' or
                   sw(pos_t3)='1' then
                        hit_done <= true;
                        total_hits <= total_hits + 1;

                        -- Crestere viteza la fiecare 5 puncte
                        if ((total_hits + 1) mod 5) = 0 then
                            if tick_max > 2000000 then
                                tick_max <= tick_max - 2000000;
                            end if;
                        end if;

                        if score0 = 9 then
                            score0 <= 0;
                            if score1 = 9 then
                                score1 <= 0;
                                if score2 = 9 then
                                    score2 <= 0;
                                    if score3 = 9 then
                                        score3 <= 0;
                                    else
                                        score3 <= score3 + 1;
                                    end if;
                                else
                                    score2 <= score2 + 1;
                                end if;
                            else
                                score1 <= score1 + 1;
                            end if;
                        else
                            score0 <= score0 + 1;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Proces afisare: PWM si 7 Segmente
    process(clk)
        variable led_temp : std_logic_vector(15 downto 0);
    begin
        if rising_edge(clk) then
            if refresh_cnt >= 100000 then
                refresh_cnt <= 0;
                if active_digit = 3 then
                    active_digit <= 0;
                else
                    active_digit <= active_digit + 1;
                end if;
            else
                refresh_cnt <= refresh_cnt + 1;
            end if;

            if pwm_tick_cnt >= 10000 then
                pwm_tick_cnt <= 0;
                if pwm_cnt = 3 then
                    pwm_cnt <= 0;
                else
                    pwm_cnt <= pwm_cnt + 1;
                end if;
            else
                pwm_tick_cnt <= pwm_tick_cnt + 1;
            end if;

            led_temp := (others => '0');
            led_temp(pos) := '1';

            if pwm_cnt < 3 then
                led_temp(pos_t1) := '1';
            end if;
            if pwm_cnt < 2 then
                led_temp(pos_t2) := '1';
            end if;
            if pwm_cnt < 1 then
                led_temp(pos_t3) := '1';
            end if;

            led <= led_temp;
        end if;
    end process;

    -- Selectie Anozi
    process(active_digit, score0, score1, score2, score3)
    begin
        case active_digit is
            when 0 =>
                an <= "1110"; current_val <= score0;
            when 1 =>
                an <= "1101"; current_val <= score1;
            when 2 =>
                an <= "1011"; current_val <= score2;
            when 3 =>
                an <= "0111"; current_val <= score3;
            when others =>
                an <= "1111"; current_val <= 0;
        end case;
    end process;

    -- Decodor 7 Segmente
    process(current_val)
    begin
        case current_val is
            when 0 => seg <= "1000000";
            when 1 => seg <= "1111001";
            when 2 => seg <= "0100100";
            when 3 => seg <= "0110000";
            when 4 => seg <= "0011001";
            when 5 => seg <= "0010010";
            when 6 => seg <= "0000010";
            when 7 => seg <= "1111000";
            when 8 => seg <= "0000000";
            when 9 => seg <= "0010000";
            when others => seg <= "1111111";
        end case;
    end process;

end Behavioral;