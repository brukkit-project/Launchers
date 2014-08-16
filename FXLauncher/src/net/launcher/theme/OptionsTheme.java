package net.launcher.theme;

import java.awt.Color;
import javax.swing.border.EmptyBorder;

import net.launcher.components.Align;
import net.launcher.components.ButtonStyle;
import net.launcher.components.CheckboxStyle;
import net.launcher.components.ComponentStyle;
import net.launcher.components.TextfieldStyle;

public class OptionsTheme
{	
	public static ComponentStyle	panelOpt	= new ComponentStyle(225, 105, 400, 300, "font", 16F, Color.DARK_GRAY, true);
	
	public static CheckboxStyle		loadnews	= new CheckboxStyle(250, 150, 300, 23, "font", "checkbox", 16F, Color.DARK_GRAY, true);
    public static CheckboxStyle		Music	    = new CheckboxStyle(250, 275, 300, 23, "font", "checkbox", 16F, Color.DARK_GRAY, true);
	public static CheckboxStyle		updatepr	= new CheckboxStyle(250, 175, 300, 23, "font", "checkbox", 16F, Color.DARK_GRAY, true);
	public static CheckboxStyle		cleandir	= new CheckboxStyle(250, 200, 300, 23, "font", "checkbox", 16F, Color.DARK_GRAY, true);
	public static CheckboxStyle		fullscrn	= new CheckboxStyle(250, 225, 300, 23, "font", "checkbox", 16F, Color.DARK_GRAY, true);
	public static CheckboxStyle		offline		= new CheckboxStyle(250, 250, 300, 23, "font", "checkbox", 16F, Color.DARK_GRAY, true);
	public static TextfieldStyle	memory		= new TextfieldStyle(235, 364, 250, 36, "textfield", "font", 16F, Color.DARK_GRAY, Color.WHITE, new EmptyBorder(0, 10, 0, 10));
	public static ButtonStyle		close		= new ButtonStyle	(500, 360, 120, 40, "font", "button", 16F, Color.RED, true, Align.CENTER);
	
	public static FontBundle		memoryDesc	= new FontBundle("font", 16F, Color.DARK_GRAY);
	
	public static int titleX 		= 362;
	public static int titleY 		= 140;
}