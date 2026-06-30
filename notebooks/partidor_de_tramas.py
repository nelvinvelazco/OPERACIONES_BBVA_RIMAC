from tkinter import Tk, StringVar, BooleanVar, END
from tkinter import filedialog, messagebox, Label, Frame, Button, Checkbutton, Text, font, Entry
import re
import os
from datetime import datetime


def limpiar_linea(linea: str) -> str:
    linea= re.sub(r'[^\x20-\x7E\n\r]|\t', ' ', linea)
    return linea


def agrupar_por_tipo(archivo_entrada):
    grupos = {}
    limpiar_trama = var_check.get()
    with open(archivo_entrada, 'r', encoding='latin-1', errors='ignore') as file_txt:
        for linea in file_txt:
            linea_trama= linea
            if limpiar_trama:
                linea_trama = limpiar_linea(linea)
            tipo = linea_trama[:3]
            if (tipo == '803') & (linea_trama[639:641]!= '01'):
                tipo= '803_TLMK'
            if tipo not in grupos:
                grupos[tipo] = []
            grupos[tipo].append(linea_trama)
    return grupos


def guardar_por_tipo(grupos, destino):
    os.makedirs(destino, exist_ok=True)
    for tipo, lineas in grupos.items():
        ruta_salida = os.path.join(destino, f"prod_{tipo}.txt")
        escribir_log(f"📦 Producto {tipo}: ({len(lineas)} registros)")
        with open(ruta_salida, 'w', encoding='utf-8') as f:
            for linea in lineas:
                f.write(linea)
        escribir_log(f"✅ Producto {tipo} guardado en: {ruta_salida}")


def seleccionar_archivo():
    ruta = filedialog.askopenfilename(
        title="Selecciona el archivo",
        filetypes=[("Archivos de texto", "*.txt")]
    )
    if ruta:
        ruta_archivo.set(ruta)
    return

def seleccionar_destino():
    ruta = filedialog.askdirectory(
        title="Selecciona carpeta destino"
    )
    if ruta:
        ruta_destino.set(ruta)
    return


def escribir_log(mensaje):
    text_log.config(state="normal")
    text_log.insert(END, mensaje + "\n")
    text_log.config(state="disabled")
    text_log.see(END)
    ventana.update()
    return


def procesar_archivo():
    ruta = ruta_archivo.get()
    destino = ruta_destino.get()
    file_name = os.path.basename(ruta)
    destino = f"{destino}\{file_name} - {fecha_hora}"
    if not ruta:
        messagebox.showwarning("Advertencia", "Debes seleccionar un archivo", parent= ventana)
        return
    escribir_log("⏳ Leyendo archivo ...")
    grupos = agrupar_por_tipo(ruta)
    escribir_log(f"✅ Se encontraron {len(grupos)} Productos distintos")
    escribir_log("💾 Guardando archivos...")
    guardar_por_tipo(grupos, destino)
    escribir_log("🎉 Proceso finalizado")
    return

ventana = Tk()


default_font = font.nametofont("TkDefaultFont")
default_font.configure(size=10)
ventana.option_add("*Font", default_font)


ventana.title("Partidor de tramas")
ventana.geometry("600x400")  # ancho x alto
ventana.resizable(False, False)

ruta_archivo= StringVar()
ruta_destino = StringVar(value="C:/TRAMAS/")
var_check = BooleanVar(value=True) 
fecha_hora = datetime.now().strftime("%Y-%m-%d_%H%M%S")


label = Label(ventana, text="Seleccione el archivo trama (.txt)")
label.pack(side="top", anchor="w", padx=10, pady=3)

frame_boton_y_check = Frame(ventana)
frame_boton_y_check.pack(anchor="w", padx=10, pady=5)

boton_selec = Button(frame_boton_y_check, text="CARGAR ARCHIVO", command=seleccionar_archivo)
boton_selec.pack(side="left")

check_limpieza = Checkbutton(frame_boton_y_check, text="Limpiar Tramas", variable=var_check)
check_limpieza.pack(side="left", padx=30)

frame_archivo = Frame(ventana)
frame_archivo.pack(anchor="w", padx=10, pady=1)

label_Archivo = Label(frame_archivo, text="Archivo:")
label_Archivo.pack(side="left")

label_ruta = Label(frame_archivo, textvariable=ruta_archivo)
label_ruta.pack(side="left", padx=5, )

text_log = Text(ventana, bg="black", fg="white", font=("Consolas", 10), height=17, width=85)
text_log.pack(side="top", anchor="w", padx=10, pady=1)

frame_boton_procesar = Frame(ventana)
frame_boton_procesar.pack(anchor="w", padx=10, pady=5)

boton_procesar = Button(frame_boton_procesar, text="PROCESAR ARCHIVO", command=procesar_archivo)
boton_procesar.pack(side="left")

frame_destino = Frame(frame_boton_procesar)
frame_destino.pack(anchor="w", padx=30)

label_destino = Label(frame_destino, text="Destino:")
label_destino.pack(side="left", padx=1)

entry_destino = Entry(frame_destino, textvariable=ruta_destino, width=40, 
                    state="readonly", readonlybackground="white", relief="flat")
entry_destino.pack(side="left", padx=5)

Boton_destino = Button(frame_destino, text="...", command=seleccionar_destino)
Boton_destino.pack(side="left", padx=5)


ventana.mainloop()
