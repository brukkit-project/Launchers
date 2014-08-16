/* Данный класс отвечает за хранение координат всех компонентов личного кабинета лаунчера */

package net.launcher.theme;

import java.awt.Color;

import javax.swing.border.EmptyBorder;

import net.launcher.components.Align;
import net.launcher.components.ButtonStyle;
import net.launcher.components.ComponentStyle;
import net.launcher.components.TextfieldStyle;

public class PersonalTheme
{
	public static ComponentStyle	ugroup		= new ComponentStyle(20, 318, 140, -1, "font", 16F, Color.DARK_GRAY, true);
	
	public static int	  skinX			= 26;
	public static int	  skinY			= 57;
	public static int	  cloakX		= 230;
	public static int	  cloakY		= 56;
	
	public static ComponentStyle cloakPrice	  = new ComponentStyle(360, 203, -1, -1, "font", 14F, Color.GREEN, true);
	public static ComponentStyle iConomy	  = new ComponentStyle(700, 82, -1, -1, "font", 18F, Color.GREEN, true);
	public static ComponentStyle realmoney	  = new ComponentStyle(700, 102, -1, -1, "font", 18F, Color.GREEN, true);
	public static ComponentStyle prices		  = new ComponentStyle(400, 230, -1, -1, "font", 16F, Color.WHITE, true);
	
	public static ButtonStyle	 buyCloak	  = new ButtonStyle(180, 230, 180, 40, "font", "button", 16F, Color.RED, true, Align.CENTER);
	public static ButtonStyle	 changeskin	  = new ButtonStyle(180, 280, 180, 40, "font", "button", 16F, Color.GREEN, true, Align.CENTER);
	public static ButtonStyle	 buyVip		  = new ButtonStyle(20, 370, 140, 40, "font", "button", 16F, Color.GREEN, true, Align.CENTER);
	public static ButtonStyle	 buyPremium	  = new ButtonStyle(20, 410, 140, 40, "font", "button", 14F, Color.YELLOW, true, Align.CENTER);
	public static ButtonStyle	 buyUnban	  = new ButtonStyle(20, 450, 140, 40, "font", "button", 16F, Color.RED, true, Align.CENTER);
	
	public static TextfieldStyle vaucher	  = new TextfieldStyle(400, 134, 280, 36, "textfield", "font", 16F, Color.WHITE, Color.WHITE, new EmptyBorder(0, 10, 0, 10));
	public static ButtonStyle	 vaucherButton= new ButtonStyle(550, 180, 130, 40, "font", "button", 16F, Color.YELLOW, true, Align.CENTER);
	public static ButtonStyle	 buyVaucher	  = new ButtonStyle(400, 180, 140, 40, "font", "button", 16F, Color.RED, true, Align.CENTER);
	
	public static TextfieldStyle exchangeFrom = new TextfieldStyle(180, 450, 160, 36, "textfield", "font", 16F, Color.WHITE, Color.WHITE, new EmptyBorder(0, 10, 0, 10));
	public static TextfieldStyle exchangeTo	  = new TextfieldStyle(385, 450, 160, 36, "textfield", "font", 16F, Color.WHITE, Color.WHITE, new EmptyBorder(0, 10, 0, 10));
	public static ButtonStyle	 exchangeBtn  = new ButtonStyle(580, 448, 130, 40, "font", "button", 16F, Color.YELLOW, true, Align.CENTER);
	
	public static ButtonStyle	 toGamePSL    = new ButtonStyle(746, 448, 88, 40, "font", "button", 16F, Color.RED, true, Align.CENTER);
}