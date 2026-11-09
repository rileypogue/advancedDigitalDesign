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
    signal borderH, borderV, gridH, gridV, hatchH, hatchV, ch1T, ch2V : STD_LOGIC;
    constant HATCHH_CENTER :   STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0) := std_logic_vector(to_unsigned(640, VIDEO_WIDTH_IN_BITS));
    constant HATCHV_CENTER :   STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0) := std_logic_vector(to_unsigned(360, VIDEO_WIDTH_IN_BITS));
    constant TRIANGLE_WIDTH:   std_logic_vector(3 downto 0) := "1111";

    



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
                if ((ch1T = '1')) then -- hatch marks are white
                    red <= CH1_R;
                    green <= CH1_G;
                    blue <= CH1_B;

                elsif ((ch2V = '1')) then -- hatch marks are white
                    red <= CH2_R;
                    green <= CH2_G;
                    blue <= CH2_B;
                    
                elsif ((ch1 = '1')) then -- hatch marks are white
                    red <= CH1_R;
                    green <= CH1_G;
                    blue <= CH1_B;

                elsif ((ch2 = '1')) then -- hatch marks are white
                    red <= CH2_R;
                    green <= CH2_G;
                    blue <= CH2_B;
                    
                     
                elsif (((borderH = '1') or (borderV = '1')) and ((ch1T /= '1') or (ch2V  /= '1'))) then
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
                    


              
                else -- this is the background color
                    red <= X"00";
                    green <= X"00";
                    blue <= X"00";
                end if;
            end if;
        end if;
    end process;

-- LEFT AND RIGHT BORDERS     
    borderH <=  '1' when ( (pixelHorz >= L_EDGE) and (pixelHorz <= L_EDGE + BORDER_LINE_WIDTH) 
                            and (pixelVert >= T_EDGE) and (pixelVert <= B_EDGE))
                    or   ( (pixelHorz <= R_EDGE) and (pixelHorz >= R_EDGE - BORDER_LINE_WIDTH) 
                            and (pixelVert >= T_EDGE) and (pixelVert <= B_EDGE))
         else '0';
         
    -- TOP AND BOTTOM BORDERS         
    borderV <=  '1' when ( (pixelVert >= T_EDGE) and (pixelVert <= T_EDGE + BORDER_LINE_WIDTH) 
                            and (pixelHorz >= L_EDGE) and (pixelHorz <= R_EDGE))
                    or   ( (pixelVert <= B_EDGE) and (pixelVert >= B_EDGE - BORDER_LINE_WIDTH) 
                            and (pixelHorz >= L_EDGE) and (pixelHorz <= R_EDGE))
         else '0';
    -- HORIZONTAL GRID LINES                                          
 --ACG CODE DOWN HERE!!!
     gridH <= '1' when pixelVert = (T_EDGE + 72) or 
                         pixelVert = (T_EDGE + 144) or 
                         pixelVert = (T_EDGE + 216) or 
                         pixelVert = (T_EDGE + 288) or 
                         pixelVert = (T_EDGE + 360) or 
                         pixelVert = (T_EDGE + 432) or 
                         pixelVert = (T_EDGE + 504) or 
                         pixelVert = (T_EDGE + 576) or
                         pixelVert = (T_EDGE + 648)  
     else '0'; 
-- vertical grid lines
    gridV <= '1' when pixelHorz = (L_EDGE + 128) or 
                         pixelHorz = (L_EDGE + 256) or 
                         pixelHorz = (L_EDGE + 384) or 
                         pixelHorz = (L_EDGE + 512) or 
                         pixelHorz = (L_EDGE + 640) or 
                         pixelHorz = (L_EDGE + 768) or 
                         pixelHorz = (L_EDGE + 896) or 
                         pixelHorz = (L_EDGE + 1024) or 
                         pixelHorz = (L_EDGE + 1152)  
                         else '0'; 
 
-- horizontal hatches                        
hatchH <= '1' when (
               -- Horizontal bounding condition (factored out)
               (pixelHorz >= (HATCHH_CENTER - BORDER_LINE_WIDTH)) and 
               (pixelHorz <= (HATCHH_CENTER + BORDER_LINE_WIDTH))
           ) and (
               -- Vertical match positions
               pixelVert = (T_EDGE + 14)  or 
               pixelVert = (T_EDGE + 29)  or 
               pixelVert = (T_EDGE + 43)  or 
               pixelVert = (T_EDGE + 58)  or 
               pixelVert = (T_EDGE + 86)  or 
               pixelVert = (T_EDGE + 101) or 
               pixelVert = (T_EDGE + 115) or 
               pixelVert = (T_EDGE + 130) or 
               pixelVert = (T_EDGE + 158) or 
               pixelVert = (T_EDGE + 173) or 
               pixelVert = (T_EDGE + 187) or 
               pixelVert = (T_EDGE + 202) or 
               pixelVert = (T_EDGE + 230) or 
               pixelVert = (T_EDGE + 245) or 
               pixelVert = (T_EDGE + 259) or 
               pixelVert = (T_EDGE + 274) or 
               pixelVert = (T_EDGE + 302) or 
               pixelVert = (T_EDGE + 317) or 
               pixelVert = (T_EDGE + 331) or 
               pixelVert = (T_EDGE + 346) or 
               pixelVert = (T_EDGE + 374) or 
               pixelVert = (T_EDGE + 389) or 
               pixelVert = (T_EDGE + 403) or 
               pixelVert = (T_EDGE + 418) or 
               pixelVert = (T_EDGE + 446) or 
               pixelVert = (T_EDGE + 461) or 
               pixelVert = (T_EDGE + 475) or 
               pixelVert = (T_EDGE + 490) or 
               pixelVert = (T_EDGE + 518) or 
               pixelVert = (T_EDGE + 533) or 
               pixelVert = (T_EDGE + 547) or 
               pixelVert = (T_EDGE + 562) or 
               pixelVert = (T_EDGE + 590) or 
               pixelVert = (T_EDGE + 605) or 
               pixelVert = (T_EDGE + 619) or 
               pixelVert = (T_EDGE + 634) or 
               pixelVert = (T_EDGE + 662) or 
               pixelVert = (T_EDGE + 677) or 
               pixelVert = (T_EDGE + 691) or 
               pixelVert = (T_EDGE + 706)
           )
     else '0';                        

 -- vertical hatches
 hatchV <= '1' when (
               -- Vertical bounding condition (factored out)
               (pixelVert >= (HATCHV_CENTER - BORDER_LINE_WIDTH)) and 
               (pixelVert <= (HATCHV_CENTER + BORDER_LINE_WIDTH))
           ) and (
               -- Horizontal match positions
               pixelHorz = (L_EDGE + 26)   or 
               pixelHorz = (L_EDGE + 51)   or 
               pixelHorz = (L_EDGE + 77)   or 
               pixelHorz = (L_EDGE + 102)  or 
               pixelHorz = (L_EDGE + 154)  or 
               pixelHorz = (L_EDGE + 179)  or 
               pixelHorz = (L_EDGE + 205)  or 
               pixelHorz = (L_EDGE + 230)  or 
               pixelHorz = (L_EDGE + 282)  or 
               pixelHorz = (L_EDGE + 307)  or 
               pixelHorz = (L_EDGE + 333)  or 
               pixelHorz = (L_EDGE + 358)  or 
               pixelHorz = (L_EDGE + 410)  or 
               pixelHorz = (L_EDGE + 435)  or 
               pixelHorz = (L_EDGE + 461)  or 
               pixelHorz = (L_EDGE + 486)  or 
               pixelHorz = (L_EDGE + 538)  or 
               pixelHorz = (L_EDGE + 563)  or 
               pixelHorz = (L_EDGE + 589)  or 
               pixelHorz = (L_EDGE + 614)  or 
               pixelHorz = (L_EDGE + 666)  or 
               pixelHorz = (L_EDGE + 691)  or 
               pixelHorz = (L_EDGE + 717)  or 
               pixelHorz = (L_EDGE + 742)  or 
               pixelHorz = (L_EDGE + 794)  or 
               pixelHorz = (L_EDGE + 819)  or 
               pixelHorz = (L_EDGE + 845)  or 
               pixelHorz = (L_EDGE + 870)  or 
               pixelHorz = (L_EDGE + 922)  or 
               pixelHorz = (L_EDGE + 947)  or 
               pixelHorz = (L_EDGE + 973)  or 
               pixelHorz = (L_EDGE + 998)  or 
               pixelHorz = (L_EDGE + 1050) or 
               pixelHorz = (L_EDGE + 1075) or 
               pixelHorz = (L_EDGE + 1101) or 
               pixelHorz = (L_EDGE + 1126) or 
               pixelHorz = (L_EDGE + 1178) or 
               pixelHorz = (L_EDGE + 1203) or 
               pixelHorz = (L_EDGE + 1229) or 
               pixelHorz = (L_EDGE + 1254)
           )
     else '0';  
     
    -- Time Marker Triangle (Top edge, pointing down to TriggerTime)
    ch1T <= '1' when 
        (pixelVert <= TRIANGLE_WIDTH) and 
        (pixelHorz >= (TriggerTime - TRIANGLE_WIDTH + pixelVert)) and 
        (pixelHorz <= (TriggerTime + TRIANGLE_WIDTH - pixelVert))
    else '0'; 

    -- Voltage Marker Triangle (Left edge, pointing right to TriggerVoltage)
    ch2V <= '1' when 
        (pixelHorz <= TRIANGLE_WIDTH) and 
        (pixelVert >= (TriggerVolt - TRIANGLE_WIDTH + pixelHorz)) and 
        (pixelVert <= (TriggerVolt + TRIANGLE_WIDTH - pixelHorz))
    else '0';

end Behavioral;


