unit LauncherSettings;

interface

const
  LauncherVersion: Byte = 0; // Defina a versão do seu Launchar (só números!!!!)

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

{$I Definitions.inc}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

const
  GlobalSalt: string = 'Sal';

{$IFDEF BEACON}
// Intervalo entre as verificações somas de verificação durante o jogo:
  BeaconDelay: Cardinal = 3000; // Em milissegundos!
{$ENDIF}

{$IFDEF EURISTIC_DEFENCE}
// Intervalo entre os clientes que executam em busca paralela:
  EuristicDelay: Cardinal = 3000;
{$ENDIF}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

var
// IP e porta do seu servidor
  PrimaryIP: string = '127.0.0.1'; // IP principal
  SecondaryIP: string = '127.0.0.1'; // IP secundário - caso não consiga se conectar pelo principal, o launcher irá tentar pelo secundário
                                     // pode ser o mesmo IP nos dois.

  ServerPort: Word = 65533;   // Porta de ligação
  GamePort: string = '25565'; // Porta do servidor

// IP e porta de escape (caso você use)
  {$IFDEF MULTISERVER}
  DistributorPrimaryIP: PAnsiChar = '127.0.0.1';
  DistributorSecondaryIP: PAnsiChar = '127.0.0.1';
  DistributorPort: Word = 65534;
  {$ENDIF}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Localização dos arquvios php para envio das skins e capas (deve estar no host do seu site, por exemplo)
  SkinUploadAddress: string = 'http://meusite.com/Minecraft/upload_skin.php';
  CloakUploadAddress: string = 'http://meusite.com/Minecraft/upload_cloak.php';

// Pastas onde ficarão as skins e capas enviadas:
  SkinDownloadAddress: string = 'http://meusite.com/Minecraft/MinecraftSkins';
  CloakDownloadAddress: string = 'http://meusite.com/Minecraft/MinecraftCloaks';

// Endereço para atualizações do launcher e jogo
  ClientAddress: string = 'http://meusite.com/Minecraft/Main.zip';
  AssetsAddress: string = 'http://meusite.com/Minecraft/Assets.zip';

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Não modifique isso:
  ClientTempArchiveName: string = '_$RCVR.bin';
  AssetsTempArchiveName: string = '_$ASTS.bin';

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// processo da máquina virtual (java.exe - console, javaw.exe - sem console):
  JavaApp: string = 'javaw.exe';

// Aqui estão os parâmetros da máquina virtual, você pode alterá-los
  JVMParams: string = '';
{
  JVMParams: string = '-server ' +
                      '-D64 ' +
                      '-XX:MaxPermSize=512m ' +
                      '-XX:+UnlockCommercialFeatures ' +
                      '-XX:+UseLargePages ' +
                      '-XX:+AggressiveOpts ' +
                      '-XX:+UseAdaptiveSizePolicy ' +
                      '-XX:+UnlockExperimentalVMOptions ' +
                      '-XX:+UseG1GC ' +
                      '-XX:UseSSE=4 ' +
                      '-XX:+DisableExplicitGC ' +
                      '-XX:MaxGCPauseMillis=100 ' +
                      '-XX:ParallelGCThreads=8 ' +
                      '-DJINTEGRA_NATIVE_MODE ' +
                      '-DJINTEGRA_COINIT_VALUE=0 ' +
                      '-Dsun.io.useCanonCaches=false ' +
                      '-Djline.terminal=jline.UnsupportedTerminal ' +
                      '-XX:ThreadPriorityPolicy=42 ' +
                      '-XX:CompileThreshold=1500 ' +
                      '-XX:+TieredCompilation ' +
                      '-XX:TargetSurvivorRatio=90 ' +
                      '-XX:MaxTenuringThreshold=15 ' +
                      '-XX:+UnlockExperimentalVMOptions ' +
                      '-XX:+UseAdaptiveGCBoundary ' +
                      '-XX:PermSize=1024M ' +
                      '-XX:+UseGCOverheadLimit ' +
                      '-XX:+UseBiasedLocking ' +
                      '-Xnoclassgc ' +
                      '-Xverify:none ' +
                      '-XX:+UseThreadPriorities ' +
                      '-Djava.net.preferIPv4Stack=true ' +
                      '-XX:+UseStringCache ' +
                      '-XX:+OptimizeStringConcat ' +
                      '-XX:+UseFastAccessorMethods ' +
                      '-Xrs ' +
                      '-XX:+UseCompressedOops ';
}

// Caminho da pasta principal, onde o java.exe se encontra
// juntamente com o cliente (Main.zip):
  {$IFDEF CUSTOM_JAVA}
  JavaDir: string = 'java\bin'; // O caminho para java(w).exe em %APPDATA%\MainFolder\
  {$ENDIF}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  MainFolder: string = '\.NTLauncher'; // Pasta do servidor em %APPDATA%: %APPDATA\MainFolder
  RegistryPath: string = 'NTLauncher'; // Nome nas keys do windows HKEY_CURRENT_USER\\Software\\

// Local da pasta Natives dentro da MainFolder (%APPDATA%\MainFolder\NativesPath):
  NativesPath: string = '\versions\Natives';

// O caminho para a pasta com o cliente em MainFolder (%APPDATA%\MainFolder\MineJarPath):
  MineJarFolder: string = '\versions\Region52';

// O caminho para a pasta com os recursos (Assets) na pasta MainFolder (%APPDATA%\MainFolder\MineJarPath):
  AssetsFolder: string = '\assets';

  GameVersion: string = '1.7.5'; // Versão do jogo (igual do ser servidor)
  AssetIndex: string = '1.7.4';  // Suporte até essa versão

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// A classe principal:

  // Caso seu servidor seja 1.5.2, utlize:
  //MainClass: string = 'net.minecraft.client.Minecraft';

  // Para versões acima da 1.6:
  //MainClass: string = 'net.minecraft.client.main.Main';

  // Forge, Optifine:
  MainClass: string = 'net.minecraft.launchwrapper.Launch';


// Classes adicionais para apoiar o Forge, LiteLoader, Optifine, GLSL Shaders, etc.:

  // Minecraft puro:
  //TweakClass: string = '';

  // Forge:
  //TweakClass: string = '--tweakClass cpw.mods.fml.common.launcher.FMLTweaker';

  // OptiFine + GLSL Shaders sem Forge:
  TweakClass: string = '--tweakClass optifine.OptiFineTweaker --tweakClass shadersmodcore.loading.SMCTweaker';




implementation

end.
