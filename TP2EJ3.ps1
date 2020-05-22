<# 
.SYNOPSIS
El script recibe un directorio con archivos de log, en los cuales busca archivos de log de las empresas. Tomando todos los archivos (excepto el último creado) y eliminàndolos del directorio.


.DESCRIPTION
Para ejecutar el Script se debe enviar una ruta valida con el path de los archivos de log (Anteponiendo -Directorio). 

El script realizará la búsqueda y eliminación cada vez que un archivo nuevo se cree. 

Paramentros a enviar:
--------------------

-Directorio path_directorio

El path del directorio puede ser una ruta tanto absoluta como relativa.

.NOTES
# ALUMNOS GRUPO 8 - Trabajo Practico 2
# Ejercicio 3
# 40231779 - Cocciardi, Agustin
# 40078823 - Biscaia, Elías
# 40388978 - Varela, Daniel
# 37841788 - Sullca, Willian
# 38056215 - Aguilera, Erik 
#>

Param( 
    [Parameter(Mandatory=$true)][string] $Directorio
)

$ruta = Test-Path $Directorio
if($ruta -ne $true)
	{Write-Host "El path de los archivos de log no es válido."
	 exit 1;
    }

    $PathToMonitor = Resolve-Path $Directorio

    $actual = $PWD

    Set-Location $PathToMonitor
    
    $FileSystemWatcher = New-Object System.IO.FileSystemWatcher
    $FileSystemWatcher.Path  = $PathToMonitor
    $FileSystemWatcher.IncludeSubdirectories = $false
    
    # make sure the watcher emits events
    $FileSystemWatcher.EnableRaisingEvents = $true
    
    # define the code that should execute when a file change is detected
    $Action = {
        #$details = $event.SourceEventArgs
        #$Name = $details.Name
        #$FullPath = $details.FullPath
        #$OldFullPath = $details.OldFullPath
        #$OldName = $details.OldName
        #$ChangeType = $details.ChangeType
        #$Timestamp = $event.TimeGenerated
        #$text = "{0} was {1} at {2}" -f $FullPath, $ChangeType, $Timestamp
        #Write-Host ""
        #Write-Host $text -ForegroundColor Green
    
        #Write-Host "Archivo Nuevo ha sido creado"
        
        $archivos= Get-ChildItem $Directorio
    
        $ArchivosATrabajar = @()
    
        for ($i = 0; $i -lt $archivos.Length; $i++) {
            if ($archivos[$i].Name -match "^[a-z]*-[0-9]+(\.)log$") {
                $ArchivosATrabajar += $archivos[$i]
            }
        }
    
        $nombres = @()
        for ($i = 0; $i -lt $ArchivosATrabajar.Length; $i++) {
            #Remove-Item $ArchivosATrabajar[$i]
            $name = $ArchivosATrabajar[$i].Name.Split('-')
            $nombreInd = $name[0]
            #Write-Host "$nombreInd"
            $estaEnLista = $false
            for ($j = 0; $j -lt $nombres.Length; $j++) {
                if ($nombreInd -eq $nombres[$j]) {
                    $estaEnLista = $true
                }    
            }
            if ($estaEnLista -eq $false) {
                $nombres += $nombreInd
            }
        }
    
        $noBorrar = @()
        for ($i = 0; $i -lt $nombres.Length; $i++) {
            $nombreABuscar = $nombres[$i]
            $mayor = 0
            for ($j = 0; $j -lt $ArchivosATrabajar.Length; $j++) {
                $nombreTrabajo = $ArchivosATrabajar[$j].Name
                if ($nombreTrabajo -match "$nombreABuscar") {
                    #Write-Output "$nombreTrabajo coincide con $nombreABuscar"
                    $name = $ArchivosATrabajar[$j].Name
                    $datos = $name.Split('-')
                    #Write-Output $datos[1]
                    $numb = $datos[1].Split('.')
                    $numero = $numb[0] -as [Int]
                    if($numero -gt $mayor){
                        $mayor = $numero
                    }
                }
            }
            $Regex="$nombreABuscar"
            $Regex+="-"
            $Regex+="$mayor"
            $Regex+=".log"
            $noBorrar += $Regex
        }
    
        for($i = 0; $i -lt $ArchivosATrabajar.Length; $i++){
            $borrar=$true
            for($j = 0; $j -lt $noBorrar.Length; $j++){
                if($ArchivosATrabajar[$i].Name -eq $noBorrar[$j]){
                    $borrar=$false
                }
            }
            if($borrar -eq $true){
                Remove-Item $ArchivosATrabajar[$i]
            }
        }
    }
    
    # add event handlers
    $handlers = . {
        Register-ObjectEvent -InputObject $FileSystemWatcher -EventName Created -Action $Action -SourceIdentifier FSCreate
    }
    
    Write-Host "Esperando cambios en $PathToMonitor"
    
    try
    {
        do
        {
            Wait-Event -Timeout 1
            #Write-Host "." -NoNewline
            
        } while ($true)
    }
    finally
    {
        # this gets executed when user presses CTRL+C
        # remove the event handlers
        Set-Location $actual
        Unregister-Event -SourceIdentifier FSCreate
        # remove background jobs
        $handlers | Remove-Job
        # remove filesystemwatcher
        $FileSystemWatcher.EnableRaisingEvents = $false
        $FileSystemWatcher.Dispose()
        "Event Handler disabled."
        
    }