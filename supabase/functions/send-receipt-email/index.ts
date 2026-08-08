import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { PDFDocument, StandardFonts, rgb } from "https://esm.sh/pdf-lib@1.17.1";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") ?? "";
const MAIL_FROM = Deno.env.get("MAIL_FROM") ?? "FastNetStays <no-reply@fastnetstays.com>";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface ReceiptPayload {
  email: string;
  guest_name: string;
  guest_phone: string;
  booking_code: string;
  lodge_name: string;
  room_number: string;
  location: string;
  dates: string;
  num_nights: number;
  price_per_night: number;
  payment_method: string;
  payment_time?: string;
  amount: number;
  receipt_url?: string;
}

function formatTsh(amount: number): string {
  return "TSh " + amount.toLocaleString("en-US");
}

function toAscii(input: string): string {
  return input
    .split("")
    .map((ch) => {
      const code = ch.charCodeAt(0);
      if (code > 127) return ch === "\u2013" || ch === "\u2014" ? "-" : " ";
      return ch;
    })
    .join("");
}

async function buildReceiptPdf(data: ReceiptPayload): Promise<Uint8Array> {
  const doc = await PDFDocument.create();
  const font = await doc.embedFont(StandardFonts.Helvetica);
  const bold = await doc.embedFont(StandardFonts.HelveticaBold);

  const page = doc.addPage([595.28, 841.89]);
  const { width, height } = page.getSize();

  const roomTotal = Math.round(data.price_per_night * data.num_nights);
  const vatTotal = Math.round(roomTotal * 0.125);
  const serviceFee = 5000;
  const grandTotal = roomTotal + vatTotal + serviceFee;
  const transactionId = "FNS-" + data.booking_code.replaceAll("-", "");

  const navy = rgb(0, 0.21, 0.5);
  const blue = rgb(0, 0.42, 0.89);
  const green = rgb(0, 0.5, 0.04);
  const grey = rgb(0.35, 0.35, 0.35);
  const black = rgb(0, 0, 0);
  const white = rgb(1, 1, 1);

  // Border frame
  page.drawRectangle({
    x: 22,
    y: 22,
    width: width - 44,
    height: height - 44,
    borderColor: black,
    borderWidth: 1,
  });

  let y = height - 60;

  // Header: brand
  page.drawText("FASTNET", { x: 55, y, size: 22, font: bold, color: navy });
  const fastnetWidth = bold.widthOfTextAtSize("FASTNET", 22);
  page.drawText("STAYS", { x: 55 + fastnetWidth, y, size: 22, font: bold, color: rgb(0.8, 0.1, 0.1) });
  const staysWidth = bold.widthOfTextAtSize("STAYS", 22);
  page.drawText(".com", { x: 55 + fastnetWidth + staysWidth, y: y - 6, size: 13, font: bold, color: grey });

  // Header: booking status
  page.drawText("BOOKING CONFIRMATION & E-RECEIPT", {
    x: width - 55 - bold.widthOfTextAtSize("BOOKING CONFIRMATION & E-RECEIPT", 12),
    y: y - 6,
    size: 12,
    font: bold,
    color: green,
  });
  y -= 46;

  // Top details row
  page.drawRectangle({
    x: 55,
    y: y - 74,
    width: width - 110,
    height: 74,
    borderColor: blue,
    borderWidth: 1.2,
  });
  page.drawText("REFERENCE NO.", { x: 68, y: y - 20, size: 8.5, font: bold, color: grey });
  page.drawText("337038" + data.booking_code.replaceAll("-", "").slice(0, 4), {
    x: 68,
    y: y - 38,
    size: 13,
    font: bold,
    color: navy,
  });
  page.drawText("BOOKING CODE", { x: width / 2, y: y - 20, size: 8.5, font: bold, color: grey });
  page.drawText(data.booking_code, { x: width / 2, y: y - 38, size: 13, font: bold, color: navy });
  page.drawText("TOTAL PAID", { x: width - 180, y: y - 20, size: 8.5, font: bold, color: grey });
  page.drawText(formatTsh(grandTotal), { x: width - 180, y: y - 38, size: 13, font: bold, color: green });
  y -= 120;

  // Guest details
  page.drawText("GUEST DETAILS", { x: 55, y, size: 12, font: bold, color: navy });
  y -= 18;
  page.drawRectangle({ x: 55, y: y - 1, width: width - 110, height: 1, color: grey });
  y -= 22;

  const guestRows: Array<[string, string]> = [
    ["Guest Name", toAscii(data.guest_name || "Guest User")],
    ["Phone", toAscii(data.guest_phone || "")],
    ["Email", toAscii(data.email || "")],
    ["Lodge", toAscii(data.lodge_name || "")],
    ["Room", toAscii(data.room_number || "")],
    ["Location", toAscii(data.location || "")],
    ["Dates", toAscii(data.dates || "")],
    ["Nights", String(data.num_nights || 1)],
    ["Payment Method", toAscii(data.payment_method || "")],
    ["Transaction ID", transactionId],
  ];

  for (const [label, value] of guestRows) {
    page.drawText(label.toUpperCase(), { x: 55, y, size: 9, font: bold, color: grey });
    page.drawText(value, { x: width / 2, y, size: 10, font, color: black });
    y -= 20;
  }

  y -= 20;

  // Payment summary
  page.drawText("PAYMENT SUMMARY", { x: 55, y, size: 12, font: bold, color: navy });
  y -= 20;
  const summaryCols = [["Room Charges", formatTsh(roomTotal)]];
  if (vatTotal > 0) summaryCols.push(["VAT (12.5%)", formatTsh(vatTotal)]);
  summaryCols.push(["Service Fee", formatTsh(serviceFee)]);
  summaryCols.push(["GRAND TOTAL", formatTsh(grandTotal)]);

  for (const [label, value] of summaryCols) {
    const isTotal = label === "GRAND TOTAL";
    page.drawText(label, { x: 55, y, size: isTotal ? 12 : 10, font: isTotal ? bold : font, color: isTotal ? navy : black });
    page.drawText(value, { x: width - 180, y, size: isTotal ? 12 : 10, font: isTotal ? bold : font, color: isTotal ? green : black });
    y -= isTotal ? 28 : 20;
  }

  // Footer
  const footerY = 55;
  page.drawText("Thank you for booking with FastNetStays. Present this receipt at check-in.", {
    x: 55,
    y: footerY,
    size: 9,
    font,
    color: grey,
  });

  return await doc.save();
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const data: ReceiptPayload = await req.json();
    if (!data.email || !data.booking_code || !data.lodge_name) {
      return new Response(JSON.stringify({ error: "email, booking_code and lodge_name are required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (!RESEND_API_KEY) {
      return new Response(JSON.stringify({ error: "RESEND_API_KEY is not configured" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const pdfBytes = await buildReceiptPdf(data);
    const base64Pdf = btoa(String.fromCharCode(...pdfBytes));

    // If the app already uploaded the exact phone-generated receipt, attach
    // that PDF instead so the email matches what the guest sees on screen.
    let attachmentContent = base64Pdf;
    if (data.receipt_url) {
      try {
        const pdfRes = await fetch(data.receipt_url);
        if (pdfRes.ok) {
          const uploaded = new Uint8Array(await pdfRes.arrayBuffer());
          attachmentContent = btoa(String.fromCharCode(...uploaded));
        }
      } catch (e) {
        console.warn("Failed to fetch uploaded receipt, using generated copy:", e);
      }
    }

    const amount = data.amount ?? 0;
    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: MAIL_FROM,
        to: [data.email],
        subject: `Booking Confirmed - ${toAscii(data.lodge_name)} (${data.booking_code})`,
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #003580;">Booking Confirmed!</h2>
            <p>Hello <strong>${toAscii(data.guest_name || "Guest")}</strong>,</p>
            <p>Your booking at <strong>${toAscii(data.lodge_name)}</strong> has been confirmed and paid.</p>
            <table style="border-collapse: collapse; width: 100%; margin: 16px 0;">
              <tr><td style="padding: 6px 0; color: #666;"><strong>Booking Code</strong></td><td>${data.booking_code}</td></tr>
              <tr><td style="padding: 6px 0; color: #666;"><strong>Check-in Dates</strong></td><td>${toAscii(data.dates || "-")}</td></tr>
              <tr><td style="padding: 6px 0; color: #666;"><strong>Room</strong></td><td>${toAscii(data.room_number || "-")}</td></tr>
              <tr><td style="padding: 6px 0; color: #666;"><strong>Total Paid</strong></td><td>${formatTsh(amount)}</td></tr>
            </table>
            <p>Your e-receipt PDF is attached to this email.</p>
            <p style="color: #666; font-size: 13px;">Thank you for choosing FastNetStays!</p>
          </div>
        `,
        attachments: [
          {
            filename: `${data.booking_code}-receipt.pdf`,
            content: attachmentContent,
          },
        ],
      }),
    });

    const resJson = await res.json().catch(() => ({}));

    if (!res.ok) {
      console.error("Resend error:", JSON.stringify(resJson));
      return new Response(JSON.stringify({ error: "Failed to send email", details: resJson }), {
        status: 502,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(
      JSON.stringify({
        message: "Confirmation email sent.",
        id: resJson.id ?? null,
        booking_code: data.booking_code,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (e) {
    console.error("send-receipt-email error:", e);
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
