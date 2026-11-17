package c

import (
	"math/rand"
	"time"
)

type Package struct {
	contenido 		string
}

type TipoSolicitud string

const (
	Alta TipoSolicitud = "Alta"
	Baja TipoSolicitud = "Baja"
)

type solicitud struct {
	canal 		chan Package
	tipo 		TipoSolicitud
}


func plataformaStream(canalInicio chan chan struct{}, canalConStreamer chan Package, solicitudes chan solicitud){
	var suscriptos []chan Package
	var fin chan struct{} = make(chan struct{}, 1)
	for range(3){
		solicitud := <- solicitudes
		suscriptos = append(suscriptos, solicitud.canal)
	}
	canalInicio <- fin
	for{
		select{
		case solicitud := <- solicitudes:
			if solicitud.tipo == Alta{
				suscriptos = append(suscriptos, solicitud.canal)
			}
			if solicitud.tipo == Baja{
				suscriptos = quitarCanal(suscriptos, solicitud.canal)
				if len(suscriptos) == 0{
					fin <- struct{}{}
				}
			}
		case paquete, ok := <-canalConStreamer:
			if !ok {
				return
			}
			for i := range suscriptos {
				suscriptos[i] <- paquete
			}
		}
	}
}

func quitarCanal(suscriptos []chan Package, canal chan Package) []chan Package {
	for i, suscripto := range suscriptos {
		if suscripto == canal {
			copy(suscriptos[i:], suscriptos[i+1:])
			suscriptos[len(suscriptos)-1] = nil
			return suscriptos[:len(suscriptos)-1]
		}
	}
	return suscriptos
}

func streamer(canalInicio chan chan struct{}, canalPlataforma chan Package){
	// Espero a que lleguen las 3 subs para arrancar 
	canalFin := <- canalInicio
	ticker := time.NewTicker(time.Duration(500) * time.Millisecond)
	defer ticker.Stop()
	for {
		select {
		case <-canalFin:
			close(canalPlataforma)
			return
		default:
		}

		<-ticker.C
		canalPlataforma <- Package{contenido: "El salto del papu"}
	}
}

func suscriptor(canalConPlataforma chan solicitud){
	var canalParaRecibirActualizaciones chan Package = make(chan Package)
	canalConPlataforma <- solicitud{
		tipo: Alta,
		canal: canalParaRecibirActualizaciones,
	}
	cantidad := rand.Intn(10) + 1
	for i := 0; i < cantidad; i++ {
		paquete := <- canalParaRecibirActualizaciones
		print(paquete.contenido)
	}
	canalConPlataforma <- solicitud{
		tipo: Baja,
		canal: canalParaRecibirActualizaciones,
	}
}
