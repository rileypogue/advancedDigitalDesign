----------------------------------------------------------------------------------
-- Include proper comment header block
-- ***Do not use mod operator in this code***
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.scopeToHdmi_package.all; -- potentially delete lol


entity scopeFace is
    PORT ( 	clk: in  STD_LOGIC;
         resetn : in  STD_LOGIC;
         pixelHorz : in  STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS - 1 downto 0);
         pixelVert : in  STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS -1 downto 0);
         triggerVolt: in STD_LOGIC_VECTOR (VIDEO_WIDTH_IN_BITS - 1 downto 0); -- triangles
         triggerTime: in STD_LOGIC_VECTOR (VIDEO_WIDTH_IN_BITS - 1 downto 0);
         red : out  STD_LOGIC_VECTOR(7 downto 0);
         green : out  STD_LOGIC_VECTOR(7 downto 0);
         blue : out  STD_LOGIC_VECTOR(7 downto 0);
         ch1: in STD_LOGIC; -- this to 1
         ch1Enb: in STD_LOGIC;
         ch2: in STD_LOGIC;
         ch2Enb: in STD_LOGIC);
end scopeFace;


architecture Behavioral of scopeFace is

    -- Set these signals to '1' when the features should be drawn at the current pixelHorz, pixelVert 
    -- cordinate.  These act like Feature Booleans which you will use in the process(clk) to set the 
    -- correct RGB for this pixel location. Finish and add more.
    signal borderH, borderV, gridH, gridV, hatchH, hatchV : STD_LOGIC;
    constant HATCHH_CENTER :   STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0) := std_logic_vector(to_unsigned(640, VIDEO_WIDTH_IN_BITS));
    constant HATCHV_CENTER :   STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0) := std_logic_vector(to_unsigned(360, VIDEO_WIDTH_IN_BITS));


    



begin


    ---------------------------------------------------------------------
    -- Use the Feature Booleans to set the RGB at this pixel location.
    -- The waveforms should sit "on top" of the grid.
    ---------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge (clk) then
            if resetn = '0' then
                red <= (others => '0'); -- others: fills all of the bits with 0's
                green <= (others => '0');
                blue <= (others => '0');
            else
                if ((borderH = '1') or (borderV = '1')) then
                    red <= BORDER_R; -- defined in package file!!!
                    green <= BORDER_G;
                    blue <= BORDER_B;
                    
                -- Grid Line Colors    
                elsif ((gridH = '1') or (gridV = '1')) then -- grid marks are white
                    red <= BORDER_R;
                    green <= BORDER_G;
                    blue <= BORDER_B;
                    
               -- Hatch Mark Colors
                elsif ((hatchH = '1') or (hatchV = '1')) then -- hatch marks are white
                    red <= BORDER_R;
                    green <= BORDER_G;
                    blue <= BORDER_B;               

                    -- <add elsif for each Feature Boolean>
              
                else -- this is the background color
                    red <= X"00";
                    green <= X"00";
                    blue <= X"00";
                end if;
            end if;
        end if;
    end process;

    -- LEFT AND RIGHT BORDERS     
    borderH <=	'1' when ( (pixelHorz > L_EDGE - BORDER_LINE_WIDTH) and (pixelHorz < L_EDGE + BORDER_LINE_WIDTH) 
                            and (pixelVert > T_EDGE) and (pixelVert < B_EDGE))
                    or   ( (pixelHorz > R_EDGE - BORDER_LINE_WIDTH) and (pixelHorz < R_EDGE + BORDER_LINE_WIDTH) 
                            and (pixelVert > T_EDGE) and (pixelVert < B_EDGE))
         else '0';
    -- TOP AND BOTTOM BORDERS          
    borderV <=	'1' when ( (pixelVert > T_EDGE - BORDER_LINE_WIDTH) and (pixelVert < T_EDGE + BORDER_LINE_WIDTH) 
                            and (pixelHorz > L_EDGE) and (pixelHorz < R_EDGE))
                    or   ( (pixelVert > B_EDGE - BORDER_LINE_WIDTH) and (pixelVert < B_EDGE + BORDER_LINE_WIDTH) 
                            and (pixelHorz > L_EDGE) and (pixelHorz < R_EDGE))
         else '0';
    -- HORIZONTAL GRID LINES                                          
 --ACG CODE DOWN HERE!!!
     gridH <= 1 when pixelVert = (T_EDGE + 72) or 
     pixelVert = (T_EDGE + 144) or 
     pixelVert = (T_EDGE + 216) or 
     pixelVert = (T_EDGE + 288) or 
     pixelVert = (T_EDGE + 360) or 
     pixelVert = (T_EDGE + 432) or 
     pixelVert = (T_EDGE + 504) or 
     pixelVert = (T_EDGE + 576) or
     pixelVert = (T_EDGE + 648) or 
     else; 

    gridV <= 1 when pixelVert = (L_EDGE + 72) or 
     pixelVert = (L_EDGE + 200) or 
     pixelVert = (L_EDGE + 328) or 
     pixelVert = (L_EDGE + 456) or 
     pixelVert = (L_EDGE + 584) or 
     pixelVert = (L_EDGE + 712) or 
     pixelVert = (L_EDGE + 840) or 
     pixelVert = (L_EDGE + 968) or 
     pixelVert = (L_EDGE + 1096) or 
     else; 

    hatchH <= '1' when  pixelVert = ((T_EDGE + 14) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 29) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 43) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 58) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 86) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 101) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 115) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 130) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 158) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 173) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 187) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 202) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 230) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 245) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 259) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 274) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 302) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 317) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 331) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 346) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 374) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 389) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 403) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 418) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 446) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 461) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 475) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 490) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 518) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 533) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 547) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 562) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 590) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 605) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 619) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 634) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 662) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 677) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 691) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelVert = ((T_EDGE + 706) and ((pixelHorz > (HATCHH_CENTER - BORDER_LINE_WIDTH)) or (pixelHorz < ( HATCHH_CENTER + BORDER_LINE_WIDTH)))) or 
                        else; 
    
    hatchV <= '1' when  pixelHorz = ((L_EDGE + 26) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 51) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 77) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 102) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 154) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 179) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 205) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 230) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 282) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 307) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 333) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 358) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 410) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 435) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 461) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 486) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 538) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 563) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 589) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 614) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 666) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 691) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 717) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 742) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 794) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 819) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 845) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 870) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 922) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 947) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 973) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 998) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 1050) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 1075) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 1101) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 1126) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 1178) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 1203) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 1229) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        pixelHorz = ((L_EDGE + 1254) and ((pixelVert > (HATCHV_CENTER - BORDER_LINE_WIDTH)) or (pixelVert < ( HATCHV_CENTER + BORDER_LINE_WIDTH)))) or 
                        else; 
         

end Behavioral;


