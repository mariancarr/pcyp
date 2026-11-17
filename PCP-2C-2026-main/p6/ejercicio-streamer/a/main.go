package a

import "time"

type Package struct {
	contenido 		string
}

func plataformaStream(canalConStreamer chan Package, suscriptos []chan Package){
	for{
		paquete := <- canalConStreamer
		for i:= range suscriptos{
			suscriptos[i] <- paquete
		}
	}
}

func streamer(canalPlataforma chan Package){
	ticker := time.NewTicker(time.Duration(500) * time.Millisecond)
	defer ticker.Stop()
	for range ticker.C{
		canalPlataforma <- Package{contenido: "El salto del papu"}
	}
}